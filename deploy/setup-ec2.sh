#!/usr/bin/env bash
# Prepara uma EC2 Amazon Linux 2023 para rodar a loja-roupas.
# Uso (na EC2):  sudo REPO_URL=https://github.com/<usuario>/loja-roupas.git bash setup-ec2.sh
set -euo pipefail

REPO_URL="${REPO_URL:?defina REPO_URL com a URL do repositório}"
DESTINO=/opt/loja-roupas
USUARIO=loja

echo ">> pacotes"
dnf install -y git nginx python3.11 python3.11-pip

echo ">> usuário sem privilégios '$USUARIO' (sem login)"
id "$USUARIO" >/dev/null 2>&1 || useradd --system --home-dir "$DESTINO" --shell /sbin/nologin "$USUARIO"

echo ">> código em $DESTINO"
if [ -d "$DESTINO/.git" ]; then
  sudo -u "$USUARIO" git -C "$DESTINO" pull --ff-only
else
  git clone "$REPO_URL" "$DESTINO"
  chown -R "$USUARIO:$USUARIO" "$DESTINO"
fi
# o nginx precisa ler o front; o loja.db fica gravável só pelo usuário loja
chmod 755 "$DESTINO" "$DESTINO/front" "$DESTINO/front/img"

echo ">> ambiente Python"
sudo -u "$USUARIO" python3.11 -m venv "$DESTINO/.venv"
sudo -u "$USUARIO" "$DESTINO/.venv/bin/pip" install --upgrade pip
sudo -u "$USUARIO" "$DESTINO/.venv/bin/pip" install -r "$DESTINO/requirements.txt" uvicorn

echo ">> systemd e nginx"
cp "$DESTINO/deploy/loja.service" /etc/systemd/system/loja.service
cp "$DESTINO/deploy/nginx-loja.conf" /etc/nginx/conf.d/loja.conf
nginx -t
systemctl daemon-reload
systemctl enable --now loja nginx
systemctl restart nginx

echo ">> pronto. Teste: curl http://127.0.0.1/api/produtos"
