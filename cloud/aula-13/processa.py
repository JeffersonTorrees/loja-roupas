"""Aula 13 (Cloud): Lambda loja-processa. Consome a fila loja-pedidos (batch 1).

Se der erro, a mensagem volta para a fila; na 3ª falha vai para a DLQ.
"""
import json
import time


def lambda_handler(event, context):
    for registro in event["Records"]:
        pedido = json.loads(registro["body"])
        if pedido.get("quantidade", 0) > 10:
            raise ValueError(f"quantidade inválida no pedido {pedido.get('pedido')}: {pedido['quantidade']}")
        time.sleep(1)          # finge o trabalho (estoque, pagamento, e-mail...)
        print("processed", pedido.get("pedido"))
