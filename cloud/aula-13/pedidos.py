"""Aula 13 (Cloud): Lambda loja-pedidos. Recebe o pedido e só o põe na fila (202).

Variáveis: FILA_URL (URL da loja-pedidos) e CHAVE_LOJA.
"""
import json
import os
import uuid

import boto3

sqs = boto3.client("sqs")


def resposta(status, dados):
    return {"statusCode": status, "headers": {"Content-Type": "application/json"},
            "body": json.dumps(dados, ensure_ascii=False)}


def lambda_handler(event, context):
    cabecalhos = {k.lower(): v for k, v in (event.get("headers") or {}).items()}
    if cabecalhos.get("x-api-key") != os.environ["CHAVE_LOJA"]:
        return resposta(401, {"detail": "chave da API ausente ou inválida"})
    try:
        pedido = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return resposta(400, {"detail": "o corpo precisa ser JSON"})

    pedido_id = uuid.uuid4().hex[:8]
    sqs.send_message(QueueUrl=os.environ["FILA_URL"],
                     MessageBody=json.dumps({"pedido": pedido_id, **pedido}))
    # 202 Accepted: recebido, mas ainda não processado
    return resposta(202, {"pedido": pedido_id, "status": "na fila"})
