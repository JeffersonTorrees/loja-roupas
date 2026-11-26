#!/usr/bin/env bash
# Parte C: cria a EC2 da loja (Amazon Linux 2023, t3.micro, us-east-1) na VPC padrão.
# Uso: MEU_IP=203.0.113.10 bash deploy/criar-ec2.sh
# - par de chaves loja-key: o .pem fica em ~/.ssh (FORA do repositório)
# - security group loja-web-sg: SSH 22 só de MEU_IP/32, HTTP 80 aberto
# - user-data: na 1ª inicialização roda deploy/setup-ec2.sh (o repositório é público)
# Custo: t3.micro e 30 GB de EBS no nível gratuito; o IPv4 público pode cobrar ~US$ 0,005/h.
set -euo pipefail
cd "$(dirname "$0")"
export AWS_DEFAULT_REGION=us-east-1
MEU_IP="${MEU_IP:?defina MEU_IP (veja em https://checkip.amazonaws.com)}"
REPO_URL="${REPO_URL:-https://github.com/JeffersonTorrees/loja-roupas.git}"
PEM="$HOME/.ssh/loja-key.pem"

echo ">> 1. par de chaves loja-key -> $PEM"
mkdir -p "$HOME/.ssh"
aws ec2 create-key-pair --key-name loja-key --key-type ed25519 \
  --query KeyMaterial --output text | tr -d '\r' > "$PEM"   # sem CRLF: o ssh recusa a chave no Windows
chmod 400 "$PEM" 2>/dev/null || true

echo ">> 2. security group loja-web-sg (VPC padrão)"
VPC=$(aws ec2 describe-vpcs --filters Name=is-default,Values=true --query "Vpcs[0].VpcId" --output text)
SG=$(aws ec2 create-security-group --group-name loja-web-sg \
  --description "loja: HTTP aberto, SSH so do meu IP" --vpc-id "$VPC" --query GroupId --output text)
aws ec2 authorize-security-group-ingress --group-id "$SG" --protocol tcp --port 22 --cidr "$MEU_IP/32" >/dev/null
aws ec2 authorize-security-group-ingress --group-id "$SG" --protocol tcp --port 80 --cidr 0.0.0.0/0 >/dev/null

echo ">> 3. instância t3.micro (AL2023, IMDSv2, 8 GB gp3)"
AMI=$(MSYS_NO_PATHCONV=1 aws ssm get-parameter \
  --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
  --query Parameter.Value --output text)
cat > user-data.tmp.sh <<EOF
#!/bin/bash
dnf install -y git
git clone $REPO_URL /tmp/loja-roupas
REPO_URL=$REPO_URL bash /tmp/loja-roupas/deploy/setup-ec2.sh > /var/log/loja-setup.log 2>&1
EOF
ID=$(MSYS_NO_PATHCONV=1 aws ec2 run-instances --image-id "$AMI" --instance-type t3.micro --key-name loja-key \
  --security-group-ids "$SG" --associate-public-ip-address \
  --metadata-options HttpTokens=required,HttpEndpoint=enabled \
  --block-device-mappings 'DeviceName=/dev/xvda,Ebs={VolumeSize=8,VolumeType=gp3,DeleteOnTermination=true}' \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=loja-web}]' \
  --user-data file://user-data.tmp.sh --query "Instances[0].InstanceId" --output text)
rm -f user-data.tmp.sh
echo "   instância: $ID (esperando ficar running...)"
aws ec2 wait instance-running --instance-ids "$ID"
IP=$(aws ec2 describe-instances --instance-ids "$ID" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
echo ">> pronto: http://$IP/   (o setup leva ~3 min depois do boot)"
echo "   ssh -i $PEM ec2-user@$IP"
