#!/usr/bin/env bash
# Aula 12 (Cloud), passos 2 e 3: põe a Lambda loja-api nas sub-redes PRIVADAS.
# Depois disso, sem endpoint do DynamoDB, o teste deve dar 502 (Task timed out after 3.00 s).
set -euo pipefail
export AWS_DEFAULT_REGION=us-east-1
export AWS_CLI_FILE_ENCODING=UTF-8   # no Windows, o CLI leria file:// em cp1252
id_por_nome() { aws ec2 "describe-$1" --filters "Name=tag:Name,Values=$2" --query "$3" --output text; }

VPC=$(id_por_nome vpcs loja-vpc "Vpcs[0].VpcId")
PRIV1=$(id_por_nome subnets loja-subnet-private1-us-east-1a "Subnets[0].SubnetId")
PRIV2=$(id_por_nome subnets loja-subnet-private2-us-east-1b "Subnets[0].SubnetId")

echo ">> permissão para a Lambda criar interfaces de rede na VPC"
aws iam attach-role-policy --role-name loja-api-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole

echo ">> security group loja-lambda-sg (sem entrada; saída liberada é o padrão)"
SG=$(aws ec2 create-security-group --group-name loja-lambda-sg --description "funcao da loja" \
  --vpc-id "$VPC" --query GroupId --output text)
echo "SG=$SG"

echo ">> Lambda na VPC (private1 + private2, só loja-lambda-sg). Timeout continua 3 s."
aws lambda update-function-configuration --function-name loja-api \
  --vpc-config "SubnetIds=$PRIV1,$PRIV2,SecurityGroupIds=$SG" >/dev/null
aws lambda wait function-updated --function-name loja-api

echo ">> checkpoint: 2 SubnetIds"
aws lambda get-function-configuration --function-name loja-api --query "VpcConfig.{Subnets:SubnetIds,SG:SecurityGroupIds}"
echo ">> agora rode ../aula-11/testar.sh: esperado 502 (print!)"
