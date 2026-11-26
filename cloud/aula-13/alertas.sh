#!/usr/bin/env bash
# Aula 13 (Cloud), passo 6: tópico SNS loja-alertas + e-mail + alarme na DLQ.
# Uso: EMAIL=voce@exemplo.com bash alertas.sh   (depois confirme a inscrição no e-mail)
set -euo pipefail
export AWS_DEFAULT_REGION=us-east-1
export AWS_CLI_FILE_ENCODING=UTF-8   # no Windows, o CLI leria file:// em cp1252
EMAIL="${EMAIL:?defina EMAIL}"

TOPICO=$(aws sns create-topic --name loja-alertas --query TopicArn --output text)
aws sns subscribe --topic-arn "$TOPICO" --protocol email --notification-endpoint "$EMAIL"
echo ">> abra o e-mail \"AWS Notification - Subscription Confirmation\" e clique em Confirm subscription"

aws cloudwatch put-metric-alarm --alarm-name loja-pedido-perdido \
  --alarm-description "Pedido caiu na DLQ loja-pedidos-dlq" \
  --namespace AWS/SQS --metric-name ApproximateNumberOfMessagesVisible \
  --dimensions Name=QueueName,Value=loja-pedidos-dlq \
  --statistic Maximum --period 60 --evaluation-periods 1 \
  --comparison-operator GreaterThanThreshold --threshold 0 \
  --treat-missing-data notBreaching \
  --alarm-actions "$TOPICO"
aws cloudwatch describe-alarms --alarm-names loja-pedido-perdido \
  --query "MetricAlarms[].[AlarmName,StateValue]" --output table
