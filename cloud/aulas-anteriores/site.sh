#!/usr/bin/env bash
# Pré-requisito: o site da loja no S3 (hospedagem de site estático), lendo a HTTP API loja-api.
# Uso: NOME=jeffersontorres bash site.sh          (rode de novo para republicar o front)
# ATENÇÃO: este bucket fica PÚBLICO para leitura (só o front: HTML, CSS, JS, logo).
set -euo pipefail
cd "$(dirname "$0")"
export AWS_DEFAULT_REGION=us-east-1
NOME="${NOME:?defina NOME}"
B="loja-site-$NOME"
FRONT=../../front

if ! aws s3api head-bucket --bucket "$B" 2>/dev/null; then
  echo ">> bucket $B"
  aws s3api create-bucket --bucket "$B" --region us-east-1 >/dev/null
  # site estático precisa de leitura pública: libera só as políticas públicas deste bucket
  aws s3api put-public-access-block --bucket "$B" --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=false,RestrictPublicBuckets=false
  aws s3api put-bucket-policy --bucket "$B" --policy \
    "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"LeituraPublicaDoSite\",\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":\"s3:GetObject\",\"Resource\":\"arn:aws:s3:::$B/*\"}]}"
  aws s3 website "s3://$B" --index-document index.html --error-document index.html
fi

echo ">> front com o endereço do API Gateway e o x-api-key"
API_ID=$(aws apigatewayv2 get-apis --query "Items[?Name=='loja-api'].ApiId | [0]" --output text)
URL=$(aws apigatewayv2 get-api --api-id "$API_ID" --query ApiEndpoint --output text)
cat > config.site.tmp.js <<EOF
// gerado por cloud/aulas-anteriores/site.sh: o site do S3 chama o API Gateway
const API = "$URL";
const API_HEADERS = { "x-api-key": "loja-turma-2026" };
EOF
aws s3 sync "$FRONT" "s3://$B" --delete --exclude config.js
aws s3 cp config.site.tmp.js "s3://$B/config.js" --content-type "application/javascript" --cache-control no-cache

SITE="http://$B.s3-website-us-east-1.amazonaws.com"
echo ">> site: $SITE"
echo ">> confira o CORS do API Gateway (o site precisa estar nas origens):"
aws apigatewayv2 get-api --api-id "$API_ID" --query CorsConfiguration.AllowOrigins --output text
echo "   se não estiver: aws apigatewayv2 update-api --api-id $API_ID --cors-configuration AllowOrigins=http://127.0.0.1:5500,http://localhost:5500,$SITE,AllowMethods=GET,POST,OPTIONS,AllowHeaders=content-type,x-api-key"
