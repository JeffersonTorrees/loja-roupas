#!/usr/bin/env bash
# Aula 13 (Cloud): mostra a fila a cada 2 s até zerar (Ctrl+C para sair).
# No CloudShell também dá:  watch -n 2 bash fila.sh --uma-vez
export AWS_DEFAULT_REGION=us-east-1
FILA_URL=$(aws sqs get-queue-url --queue-name loja-pedidos --query QueueUrl --output text)
DLQ_URL=$(aws sqs get-queue-url --queue-name loja-pedidos-dlq --query QueueUrl --output text)
mostrar() {
  echo "$(date +%T)  fila: $(aws sqs get-queue-attributes --queue-url "$FILA_URL" \
    --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible \
    --query 'Attributes.[ApproximateNumberOfMessages,ApproximateNumberOfMessagesNotVisible]' --output text | tr '\t' '/') (visíveis/em processamento)" \
    "  DLQ: $(aws sqs get-queue-attributes --queue-url "$DLQ_URL" --attribute-names ApproximateNumberOfMessages --query Attributes.ApproximateNumberOfMessages --output text)"
}
if [ "${1:-}" = "--uma-vez" ]; then mostrar; exit; fi
while true; do mostrar; sleep 2; done
