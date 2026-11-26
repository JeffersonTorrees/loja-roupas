#!/usr/bin/env bash
# Aula 10 (Cloud): gera arquivos de amostra (5 logs de ~200 KB, 3 "fotos" de 300 KB)
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p amostra/logs amostra/imagens

for i in 1 2 3 4 5; do
  head -c 150000 /dev/urandom | base64 > "amostra/logs/acesso-$i.log"   # ~200 KB de texto
done
for i in 1 2 3; do
  head -c 307200 /dev/urandom > "amostra/imagens/foto-$i.jpg"           # 300 KB
done

ls -lh amostra/logs amostra/imagens
