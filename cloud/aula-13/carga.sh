#!/usr/bin/env bash
# Aula 13 (Cloud), passo 5: 100 pedidos VÁLIDOS com 20 curls em paralelo. Esperado: 100 x 202.
# Uso: bash carga.sh            (STAGE=v1 bash carga.sh se o stage não for $default)
# Em outro terminal, acompanhe a fila:  bash fila.sh
set -uo pipefail
export AWS_DEFAULT_REGION=us-east-1
export AWS_CLI_FILE_ENCODING=UTF-8   # no Windows, o CLI leria file:// em cp1252
API_ID=$(aws apigatewayv2 get-apis --query "Items[?Name=='loja-api'].ApiId | [0]" --output text)
URL=$(aws apigatewayv2 get-api --api-id "$API_ID" --query ApiEndpoint --output text)
[ -n "${STAGE:-}" ] && URL="$URL/$STAGE"
export URL

echo ">> 100 POST /pedidos, 20 por vez. Contagem por status HTTP:"
seq 1 100 | xargs -P 20 -I{} sh -c 'curl -s -o /dev/null -w "%{http_code}\n" -X POST "$URL/pedidos" \
  -H "x-api-key: loja-turma-2026" -H "Content-Type: application/json" \
  -d "{\"produto\":1,\"quantidade\":2}"' | sort | uniq -c
# Se aparecer 429: throttling do stage para rate 50 / burst 100:
# aws apigatewayv2 update-stage --api-id $API_ID --stage-name '$default' \
#   --default-route-settings ThrottlingRateLimit=50,ThrottlingBurstLimit=100
