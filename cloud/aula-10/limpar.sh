#!/usr/bin/env bash
# Aula 10 (Cloud): APAGA o bucket da aula. Só rode depois dos prints!
# Uso: NOME=seunome bash limpar.sh
set -euo pipefail
NOME="${NOME:?defina NOME}"
B="loja-equipe-aula10-$NOME"
aws s3 rm "s3://$B" --recursive
aws s3 rb "s3://$B"
echo ">> checkpoint: a linha abaixo deve ficar vazia"
aws s3 ls | grep aula10 || true
