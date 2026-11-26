#!/usr/bin/env bash
# Aula 12 (Cloud), passo 4: endpoint GATEWAY do DynamoDB nas 2 tabelas de rotas PRIVADAS.
# Gateway endpoint é gratuito. (Nunca Interface endpoint: esse cobra por hora.)
set -euo pipefail
export AWS_DEFAULT_REGION=us-east-1
id_por_nome() { aws ec2 "describe-$1" --filters "Name=tag:Name,Values=$2" --query "$3" --output text; }

VPC=$(id_por_nome vpcs loja-vpc "Vpcs[0].VpcId")
RT1=$(id_por_nome route-tables loja-rtb-private1-us-east-1a "RouteTables[0].RouteTableId")
RT2=$(id_por_nome route-tables loja-rtb-private2-us-east-1b "RouteTables[0].RouteTableId")

aws ec2 create-vpc-endpoint --vpc-id "$VPC" --vpc-endpoint-type Gateway \
  --service-name com.amazonaws.us-east-1.dynamodb --route-table-ids "$RT1" "$RT2" \
  --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=loja-vpce-dynamodb}]" \
  --query "VpcEndpoint.[VpcEndpointId,VpcEndpointType,State]" --output text
# sem --policy-document = política padrão "Full access"

echo ">> rota nova na tabela privada (pl-... -> vpce-...)"
aws ec2 describe-route-tables --route-table-ids "$RT1" \
  --query "RouteTables[0].Routes[].[DestinationCidrBlock||DestinationPrefixListId,GatewayId]" --output table
echo ">> agora: bash ../aula-11/testar.sh 5 Meia 19.9   (200, 404, 201, 409)"
