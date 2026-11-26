#!/usr/bin/env bash
# Aula 10 (Cloud): bucket da equipe, upload, classe Standard-IA e ciclo de vida.
# Uso: NOME=seunome bash s3.sh
set -euo pipefail
cd "$(dirname "$0")"
export AWS_DEFAULT_REGION=us-east-1
NOME="${NOME:?defina NOME (minúsculas, sem espaço)}"
B="loja-equipe-aula10-$NOME"

echo ">> 1. bucket $B (us-east-1) com Block all public access"
aws s3api create-bucket --bucket "$B" --region us-east-1
aws s3api put-public-access-block --bucket "$B" --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo ">> 2. upload"
aws s3 cp amostra "s3://$B" --recursive
aws s3 cp amostra/imagens/foto-1.jpg "s3://$B/teste/foto-fria.jpg" --storage-class STANDARD_IA

echo ">> checkpoint: 9 objetos"
aws s3 ls "s3://$B" --recursive
aws s3 ls "s3://$B" --recursive | wc -l

echo ">> 3. ciclo de vida logs-ciclo (o print deve ser do CONSOLE, aba Management)"
aws s3api put-bucket-lifecycle-configuration --bucket "$B" --lifecycle-configuration file://regra.json
aws s3api get-bucket-lifecycle-configuration --bucket "$B" --query "Rules[].Status"
