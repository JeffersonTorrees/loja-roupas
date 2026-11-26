#!/usr/bin/env bash
# Aula 13 (Cloud), passo 7: falha proposital (quantidade 99). A loja-processa dá erro 3 vezes,
# a mensagem vai para a DLQ, o alarme vai para ALARM e o e-mail chega (1 a 3 minutos).
set -uo pipefail
export AWS_DEFAULT_REGION=us-east-1
API_ID=$(aws apigatewayv2 get-apis --query "Items[?Name=='loja-api'].ApiId | [0]" --output text)
URL=$(aws apigatewayv2 get-api --api-id "$API_ID" --query ApiEndpoint --output text)
[ -n "${STAGE:-}" ] && URL="$URL/$STAGE"

curl -s -w "\n-> HTTP %{http_code}\n" -X POST "$URL/pedidos" -H "x-api-key: loja-turma-2026" \
  -H "Content-Type: application/json" -d '{"produto": 3, "quantidade": 99}'
echo ">> acompanhe (Ctrl+C para sair): aws logs tail /aws/lambda/loja-processa --follow"
echo ">> cada nova tentativa leva ~30 s (VisibilityTimeout). Depois da 3ª, a mensagem vai para a DLQ."
echo ">> estado do alarme: aws cloudwatch describe-alarms --alarm-names loja-pedido-perdido --query 'MetricAlarms[0].StateValue'"
echo ">> para resetar depois dos prints: aws sqs purge-queue --queue-url \$(aws sqs get-queue-url --queue-name loja-pedidos-dlq --query QueueUrl --output text)"
