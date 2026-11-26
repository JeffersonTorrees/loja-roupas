#!/usr/bin/env bash
# Confere (só leitura) o que as Aulas 10–13 precisam. Não cria nem apaga nada.
set -uo pipefail
export AWS_DEFAULT_REGION=us-east-1
ok() { echo "  [ok] $1"; }; falta() { echo "  [FALTA] $1"; }

echo "== identidade e região"
aws sts get-caller-identity --query "Arn" --output text || { echo "AWS CLI não configurado"; exit 1; }
echo "  região configurada: $(aws configure get region || echo '(nenhuma)')  (os scripts forçam us-east-1)"
CONTA=$(aws sts get-caller-identity --query Account --output text)

echo "== alerta de orçamento de US\$ 1"
aws budgets describe-budgets --account-id "$CONTA" \
  --query "Budgets[].{nome:BudgetName,limite:BudgetLimit.Amount,moeda:BudgetLimit.Unit}" --output table 2>/dev/null \
  || falta "nenhum budget (ou sem permissão budgets:ViewBudget)"

echo "== pré-requisitos das aulas anteriores"
if aws lambda get-function-configuration --function-name loja-api >/dev/null 2>&1; then
  ok "Lambda loja-api ($(aws lambda get-function-configuration --function-name loja-api --query Runtime --output text))"
  aws lambda get-function-configuration --function-name loja-api \
    --query "{papel:Role,timeout:Timeout,variaveis:keys(Environment.Variables||\`{}\`),vpc:VpcConfig.SubnetIds}" --output json
else falta "Lambda loja-api"; fi
aws iam get-role --role-name loja-api-role >/dev/null 2>&1 && ok "papel loja-api-role" \
  || falta "papel loja-api-role (veja o nome real no 'papel' acima)"
API_ID=$(aws apigatewayv2 get-apis --query "Items[?Name=='loja-api'].ApiId | [0]" --output text 2>/dev/null)
if [ -z "$API_ID" ]; then
  falta "não consegui ler o API Gateway (sem permissão?)"
elif [ "$API_ID" != "None" ]; then
  ok "HTTP API loja-api ($(aws apigatewayv2 get-api --api-id "$API_ID" --query ApiEndpoint --output text))"
  aws apigatewayv2 get-routes --api-id "$API_ID" --query "Items[].RouteKey" --output text
  aws apigatewayv2 get-stages --api-id "$API_ID" --query "Items[].{stage:StageName,autoDeploy:AutoDeploy}" --output table
else falta "HTTP API loja-api"; fi
echo "== buckets S3 (o site da loja deve aparecer aqui)"
aws s3 ls
echo "== já existe algo das aulas 10–13?"
aws dynamodb describe-table --table-name loja-produtos --query "Table.TableStatus" --output text 2>/dev/null && echo "  (tabela loja-produtos existe)"
aws ec2 describe-vpcs --filters Name=tag:Name,Values=loja-vpc --query "Vpcs[].VpcId" --output text
aws sqs list-queues --queue-name-prefix loja --query QueueUrls --output text 2>/dev/null
echo "== NAT Gateways ativos (deve ser 0): $(aws ec2 describe-nat-gateways --filter Name=state,Values=available,pending --query 'length(NatGateways)')"
echo "== instâncias EC2"
aws ec2 describe-instances --query "Reservations[].Instances[].{id:InstanceId,tipo:InstanceType,estado:State.Name,ip:PublicIpAddress,nome:Tags[?Key=='Name']|[0].Value}" --output table
