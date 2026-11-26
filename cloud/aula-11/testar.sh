#!/usr/bin/env bash
# Aula 11/12 (Cloud): testes com curl. Esperado: 200, 404, 201, 409.
# Uso: bash testar.sh [id] [nome] [preco]    (padrão: 4 Boné 49.9; na Aula 12: 5 Meia 19.9)
set -uo pipefail
export AWS_DEFAULT_REGION=us-east-1
ID="${1:-4}"; NOME="${2:-Boné}"; PRECO="${3:-49.9}"
API_ID=$(aws apigatewayv2 get-apis --query "Items[?Name=='loja-api'].ApiId | [0]" --output text)
URL=$(aws apigatewayv2 get-api --api-id "$API_ID" --query ApiEndpoint --output text)
# se o stage não for $default, ponha o nome dele: STAGE=v1 bash testar.sh
[ -n "${STAGE:-}" ] && URL="$URL/$STAGE"
K="x-api-key: loja-turma-2026"

pedir() { echo "== $1"; shift; curl -s -w "\n   -> HTTP %{http_code}\n" -H "$K" "$@"; }
pedir "GET /produtos/2 (esperado 200)" "$URL/produtos/2"
pedir "GET /produtos/9 (esperado 404)" "$URL/produtos/9"
JSON="{\"id\":$ID,\"nome\":\"$NOME\",\"preco\":$PRECO}"
pedir "POST $NOME (esperado 201)" -X POST "$URL/produtos" -H "Content-Type: application/json" -d "$JSON"
pedir "POST $NOME de novo (esperado 409)" -X POST "$URL/produtos" -H "Content-Type: application/json" -d "$JSON"
