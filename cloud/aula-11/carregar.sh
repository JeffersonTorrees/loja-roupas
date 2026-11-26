#!/usr/bin/env bash
# Aula 11 (Cloud): cria a tabela loja-produtos (on-demand) e carrega 3 itens.
set -euo pipefail
cd "$(dirname "$0")"
export AWS_DEFAULT_REGION=us-east-1
export AWS_CLI_FILE_ENCODING=UTF-8   # no Windows, o CLI leria file:// em cp1252

aws dynamodb create-table --table-name loja-produtos \
  --attribute-definitions AttributeName=id,AttributeType=N \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
aws dynamodb wait table-exists --table-name loja-produtos

aws dynamodb batch-write-item --request-items file://itens.json
aws dynamodb scan --table-name loja-produtos --output table

echo ">> checkpoint: Count = 3"
aws dynamodb scan --table-name loja-produtos --select COUNT
