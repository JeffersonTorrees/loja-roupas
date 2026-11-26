#!/usr/bin/env bash
# Pré-requisitos das Aulas 11–13 (o que as aulas anteriores teriam criado):
#   papel loja-api-role, Lambda loja-api (CHAVE_LOJA) e HTTP API loja-api ($default, auto-deploy).
# Custo: nível gratuito (Lambda e API Gateway cobram só por uso).
set -euo pipefail
cd "$(dirname "$0")"
export AWS_DEFAULT_REGION=us-east-1
CONTA=$(aws sts get-caller-identity --query Account --output text)   # não versionado
SITE_ORIGEM="${SITE_ORIGEM:-}"   # ex.: http://loja-site-x.s3-website-us-east-1.amazonaws.com

echo ">> 1. papel loja-api-role (a Lambda assume este papel; só logs por enquanto)"
aws iam create-role --role-name loja-api-role --assume-role-policy-document \
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws iam attach-role-policy --role-name loja-api-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
sleep 10   # o IAM leva alguns segundos para o papel novo valer

echo ">> 2. Lambda loja-api (Python 3.12, timeout 3 s, CHAVE_LOJA)"
rm -f loja-api.zip; zip -j loja-api.zip lambda_function.py 2>/dev/null \
  || python -c "import zipfile; zipfile.ZipFile('loja-api.zip','w').write('lambda_function.py')"
aws lambda create-function --function-name loja-api --runtime python3.12 \
  --role "arn:aws:iam::$CONTA:role/loja-api-role" --handler lambda_function.lambda_handler \
  --timeout 3 --zip-file fileb://loja-api.zip \
  --environment "Variables={CHAVE_LOJA=loja-turma-2026}" >/dev/null
aws lambda wait function-active --function-name loja-api

echo ">> 3. HTTP API loja-api com CORS para o site"
ORIGENS="http://127.0.0.1:5500,http://localhost:5500${SITE_ORIGEM:+,$SITE_ORIGEM}"
API_ID=$(aws apigatewayv2 create-api --name loja-api --protocol-type HTTP \
  --cors-configuration "AllowOrigins=$ORIGENS,AllowMethods=GET,POST,OPTIONS,AllowHeaders=content-type,x-api-key" \
  --query ApiId --output text)
INTEG=$(aws apigatewayv2 create-integration --api-id "$API_ID" --integration-type AWS_PROXY \
  --integration-uri "arn:aws:lambda:us-east-1:$CONTA:function:loja-api" \
  --payload-format-version 2.0 --query IntegrationId --output text)
for ROTA in "GET /produtos" "GET /produtos/{id}" "GET /promocoes" "POST /carrinho/total"; do
  aws apigatewayv2 create-route --api-id "$API_ID" --route-key "$ROTA" --target "integrations/$INTEG" >/dev/null
  echo "   rota: $ROTA"
done
aws apigatewayv2 create-stage --api-id "$API_ID" --stage-name '$default' --auto-deploy >/dev/null
aws lambda add-permission --function-name loja-api --statement-id apigw-loja-api \
  --action lambda:InvokeFunction --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:us-east-1:$CONTA:$API_ID/*" >/dev/null

URL=$(aws apigatewayv2 get-api --api-id "$API_ID" --query ApiEndpoint --output text)
echo ">> pronto: $URL"
sleep 3
echo ">> teste sem chave (esperado 401): $(curl -s -o /dev/null -w '%{http_code}' "$URL/produtos")"
echo ">> teste com chave (esperado 200): $(curl -s -o /dev/null -w '%{http_code}' -H 'x-api-key: loja-turma-2026' "$URL/produtos")"
