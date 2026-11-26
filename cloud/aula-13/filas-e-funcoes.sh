#!/usr/bin/env bash
# Aula 13 (Cloud), passos 1 a 4: filas, Lambdas loja-pedidos e loja-processa, rota POST /pedidos.
set -euo pipefail
cd "$(dirname "$0")"
export AWS_DEFAULT_REGION=us-east-1
CONTA=$(aws sts get-caller-identity --query Account --output text)   # não versionado
zipar() { rm -f "$2"; zip -j "$2" "$1" 2>/dev/null || python -c "import zipfile,sys; zipfile.ZipFile(sys.argv[2],'w').write(sys.argv[1],'lambda_function.py')" "$1" "$2"; }
CONFIANCA='{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}'

echo ">> 1. DLQ primeiro, depois a fila principal (redrive após 3 recebimentos)"
DLQ_URL=$(aws sqs create-queue --queue-name loja-pedidos-dlq --query QueueUrl --output text)
DLQ_ARN=$(aws sqs get-queue-attributes --queue-url "$DLQ_URL" --attribute-names QueueArn --query Attributes.QueueArn --output text)
cat > fila.tmp.json <<EOF
{"VisibilityTimeout":"30","RedrivePolicy":"{\"deadLetterTargetArn\":\"$DLQ_ARN\",\"maxReceiveCount\":\"3\"}"}
EOF
FILA_URL=$(aws sqs create-queue --queue-name loja-pedidos --attributes file://fila.tmp.json --query QueueUrl --output text)
FILA_ARN=$(aws sqs get-queue-attributes --queue-url "$FILA_URL" --attribute-names QueueArn --query Attributes.QueueArn --output text)

echo ">> 2. Lambda loja-pedidos (fora da VPC, 3 s) + papel com SendMessage só na loja-pedidos"
aws iam create-role --role-name loja-pedidos-role --assume-role-policy-document "$CONFIANCA" >/dev/null
aws iam attach-role-policy --role-name loja-pedidos-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
aws iam put-role-policy --role-name loja-pedidos-role --policy-name enviar-para-loja-pedidos \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sqs:SendMessage\",\"Resource\":\"$FILA_ARN\"}]}"
CHAVE=$(aws lambda get-function-configuration --function-name loja-api \
  --query "Environment.Variables.CHAVE_LOJA" --output text)
sleep 10   # o IAM leva alguns segundos para o papel novo valer
zipar pedidos.py pedidos.zip
aws lambda create-function --function-name loja-pedidos --runtime python3.12 \
  --role "arn:aws:iam::$CONTA:role/loja-pedidos-role" --handler lambda_function.lambda_handler \
  --timeout 3 --zip-file fileb://pedidos.zip \
  --environment "Variables={FILA_URL=$FILA_URL,CHAVE_LOJA=$CHAVE}" >/dev/null
aws lambda wait function-active --function-name loja-pedidos

echo ">> 3. rota POST /pedidos no API Gateway loja-api"
API_ID=$(aws apigatewayv2 get-apis --query "Items[?Name=='loja-api'].ApiId | [0]" --output text)
INTEG=$(aws apigatewayv2 create-integration --api-id "$API_ID" --integration-type AWS_PROXY \
  --integration-uri "arn:aws:lambda:us-east-1:$CONTA:function:loja-pedidos" \
  --payload-format-version 2.0 --query IntegrationId --output text)
aws apigatewayv2 create-route --api-id "$API_ID" --route-key "POST /pedidos" --target "integrations/$INTEG" >/dev/null
aws lambda add-permission --function-name loja-pedidos --statement-id apigw-pedidos \
  --action lambda:InvokeFunction --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:us-east-1:$CONTA:$API_ID/*/POST/pedidos" >/dev/null
# se o stage NÃO tiver auto-deploy (ex.: v1), publique: aws apigatewayv2 create-deployment --api-id $API_ID --stage-name v1
aws apigatewayv2 get-stages --api-id "$API_ID" --query "Items[].{stage:StageName,autoDeploy:AutoDeploy}" --output table

echo ">> 4. Lambda loja-processa (5 s) + gatilho SQS: batch 1, concorrência máxima 2"
aws iam create-role --role-name loja-processa-role --assume-role-policy-document "$CONFIANCA" >/dev/null
aws iam attach-role-policy --role-name loja-processa-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole
sleep 10
zipar processa.py processa.zip
aws lambda create-function --function-name loja-processa --runtime python3.12 \
  --role "arn:aws:iam::$CONTA:role/loja-processa-role" --handler lambda_function.lambda_handler \
  --timeout 5 --zip-file fileb://processa.zip >/dev/null
aws lambda wait function-active --function-name loja-processa
aws lambda create-event-source-mapping --function-name loja-processa --event-source-arn "$FILA_ARN" \
  --batch-size 1 --scaling-config MaximumConcurrency=2 \
  --query "{UUID:UUID,Batch:BatchSize,Concorrencia:ScalingConfig.MaximumConcurrency}" --output table

echo ">> pronto. FILA_URL=$FILA_URL"
