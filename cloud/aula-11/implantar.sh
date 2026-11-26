#!/usr/bin/env bash
# Aula 11 (Cloud): permissão no DynamoDB, variável da tabela, código novo e rotas.
# Pré-requisitos: Lambda loja-api (papel loja-api-role) e HTTP API loja-api.
set -euo pipefail
cd "$(dirname "$0")"
export AWS_DEFAULT_REGION=us-east-1
export AWS_CLI_FILE_ENCODING=UTF-8   # no Windows, o CLI leria file:// em cp1252
CONTA=$(aws sts get-caller-identity --query Account --output text)   # não versionado

echo ">> 1. política inline loja-dynamodb no papel loja-api-role"
sed "s/CONTA/$CONTA/" politica-dynamodb.json > politica.tmp.json
aws iam put-role-policy --role-name loja-api-role --policy-name loja-dynamodb \
  --policy-document file://politica.tmp.json

echo ">> 2. variáveis: mantém CHAVE_LOJA e acrescenta TABELA_PRODUTOS"
CHAVE=$(aws lambda get-function-configuration --function-name loja-api \
  --query "Environment.Variables.CHAVE_LOJA" --output text)
aws lambda update-function-configuration --function-name loja-api \
  --environment "Variables={CHAVE_LOJA=$CHAVE,TABELA_PRODUTOS=loja-produtos}" >/dev/null
aws lambda wait function-updated --function-name loja-api

echo ">> 3. código novo"
rm -f loja-api.zip; zip -j loja-api.zip lambda_function.py 2>/dev/null || python -c "import zipfile; zipfile.ZipFile('loja-api.zip','w').write('lambda_function.py')"
aws lambda update-function-code --function-name loja-api --zip-file fileb://loja-api.zip >/dev/null
aws lambda wait function-updated --function-name loja-api

echo ">> 4. rotas no API Gateway loja-api (cria só as que faltam)"
API_ID=$(aws apigatewayv2 get-apis --query "Items[?Name=='loja-api'].ApiId | [0]" --output text)
LAMBDA_ARN=$(aws lambda get-function --function-name loja-api --query Configuration.FunctionArn --output text)
INTEG=$(aws apigatewayv2 get-integrations --api-id "$API_ID" \
  --query "Items[?IntegrationUri=='$LAMBDA_ARN'].IntegrationId | [0]" --output text)
if [ "$INTEG" = "None" ]; then
  INTEG=$(aws apigatewayv2 create-integration --api-id "$API_ID" --integration-type AWS_PROXY \
    --integration-uri "$LAMBDA_ARN" --payload-format-version 2.0 --query IntegrationId --output text)
fi
for ROTA in "GET /produtos" "GET /produtos/{id}" "POST /produtos" "POST /carrinho/total" "GET /promocoes"; do
  EXISTE=$(aws apigatewayv2 get-routes --api-id "$API_ID" --query "Items[?RouteKey=='$ROTA'] | length(@)")
  if [ "$EXISTE" = "0" ]; then
    aws apigatewayv2 create-route --api-id "$API_ID" --route-key "$ROTA" --target "integrations/$INTEG" >/dev/null
    echo "   criada: $ROTA"
  else
    echo "   já existe: $ROTA"
  fi
done
# a Lambda precisa deixar o API Gateway chamá-la (ignora se já existe)
aws lambda add-permission --function-name loja-api --statement-id apigw-loja-api-aula11 \
  --action lambda:InvokeFunction --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:us-east-1:$CONTA:$API_ID/*" >/dev/null 2>&1 || true
aws apigatewayv2 get-stages --api-id "$API_ID" --query "Items[].{stage:StageName,autoDeploy:AutoDeploy}" --output table

echo ">> URL: $(aws apigatewayv2 get-api --api-id "$API_ID" --query ApiEndpoint --output text)"
