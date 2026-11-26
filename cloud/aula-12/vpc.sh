#!/usr/bin/env bash
# Aula 12 (Cloud): a VPC "loja", igual ao assistente "VPC and more" do console:
# 10.0.0.0/16, 2 AZs, 2 sub-redes públicas + 2 privadas, SEM NAT, endpoint Gateway do S3.
# (alternativa: fazer pelo console com name tag "loja" — gera exatamente estes nomes)
set -euo pipefail
export AWS_DEFAULT_REGION=us-east-1
tag() { echo "ResourceType=$1,Tags=[{Key=Name,Value=$2}]"; }

VPC=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications "$(tag vpc loja-vpc)" \
  --query Vpc.VpcId --output text)
aws ec2 wait vpc-available --vpc-ids "$VPC"
aws ec2 modify-vpc-attribute --vpc-id "$VPC" --enable-dns-hostnames '{"Value":true}'
echo "VPC=$VPC"

sub() { aws ec2 create-subnet --vpc-id "$VPC" --cidr-block "$1" --availability-zone "$2" \
  --tag-specifications "$(tag subnet "$3")" --query Subnet.SubnetId --output text; }
PUB1=$(sub 10.0.0.0/20   us-east-1a loja-subnet-public1-us-east-1a)
PUB2=$(sub 10.0.16.0/20  us-east-1b loja-subnet-public2-us-east-1b)
PRIV1=$(sub 10.0.128.0/20 us-east-1a loja-subnet-private1-us-east-1a)
PRIV2=$(sub 10.0.144.0/20 us-east-1b loja-subnet-private2-us-east-1b)

IGW=$(aws ec2 create-internet-gateway --tag-specifications "$(tag internet-gateway loja-igw)" \
  --query InternetGateway.InternetGatewayId --output text)
aws ec2 attach-internet-gateway --internet-gateway-id "$IGW" --vpc-id "$VPC"

rtb() { aws ec2 create-route-table --vpc-id "$VPC" --tag-specifications "$(tag route-table "$1")" \
  --query RouteTable.RouteTableId --output text; }
RT_PUB=$(rtb loja-rtb-public)
RT_PRIV1=$(rtb loja-rtb-private1-us-east-1a)
RT_PRIV2=$(rtb loja-rtb-private2-us-east-1b)

# pública: tudo que não é 10.0.0.0/16 sai pelo Internet Gateway
aws ec2 create-route --route-table-id "$RT_PUB" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW" >/dev/null
aws ec2 associate-route-table --route-table-id "$RT_PUB" --subnet-id "$PUB1" >/dev/null
aws ec2 associate-route-table --route-table-id "$RT_PUB" --subnet-id "$PUB2" >/dev/null
# privadas: só a rota local (sem NAT!) + o endpoint do S3
aws ec2 associate-route-table --route-table-id "$RT_PRIV1" --subnet-id "$PRIV1" >/dev/null
aws ec2 associate-route-table --route-table-id "$RT_PRIV2" --subnet-id "$PRIV2" >/dev/null

aws ec2 create-vpc-endpoint --vpc-id "$VPC" --vpc-endpoint-type Gateway \
  --service-name com.amazonaws.us-east-1.s3 --route-table-ids "$RT_PRIV1" "$RT_PRIV2" \
  --tag-specifications "$(tag vpc-endpoint loja-vpce-s3)" >/dev/null

echo ">> checkpoints"
aws ec2 describe-vpcs --filters Name=tag:Name,Values=loja-vpc --query "Vpcs[].[VpcId,CidrBlock]" --output table
echo "sub-redes: $(aws ec2 describe-subnets --filters Name=vpc-id,Values="$VPC" --query 'length(Subnets)')   (esperado 4)"
echo "NAT ativos: $(aws ec2 describe-nat-gateways --filter Name=state,Values=available,pending --query 'length(NatGateways)')   (esperado 0)"
