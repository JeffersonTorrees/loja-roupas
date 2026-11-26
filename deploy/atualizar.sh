#!/usr/bin/env bash
# Atualiza a loja na EC2 depois de um push.  Uso: sudo bash /opt/loja-roupas/deploy/atualizar.sh
set -euo pipefail
DESTINO=/opt/loja-roupas

sudo -u loja git -C "$DESTINO" pull --ff-only
sudo -u loja "$DESTINO/.venv/bin/pip" install -r "$DESTINO/requirements.txt" uvicorn
cp "$DESTINO/deploy/loja.service" /etc/systemd/system/loja.service
cp "$DESTINO/deploy/nginx-loja.conf" /etc/nginx/conf.d/loja.conf
systemctl daemon-reload
systemctl restart loja
nginx -t && systemctl reload nginx
systemctl --no-pager status loja | head -5
