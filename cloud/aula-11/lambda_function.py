"""Aula 11 (Cloud): a Lambda loja-api agora lê e grava no DynamoDB.

Variáveis de ambiente: CHAVE_LOJA (chave da API) e TABELA_PRODUTOS (loja-produtos).
Evento: API Gateway HTTP API, payload 2.0.
"""
import base64
import json
import os
from decimal import Decimal

import boto3
from botocore.exceptions import ClientError

# fora do handler: criado uma vez por ambiente de execução (reaproveitado nas chamadas)
tabela = boto3.resource("dynamodb").Table(os.environ["TABELA_PRODUTOS"])

PROMOCOES = [{"nome": "Semana da loja", "desconto": "10% em tudo",
              "frete_gratis_a_partir_de": 200}]
DESCONTO = Decimal("0.10")
FRETE_FIXO = Decimal("15")
FRETE_GRATIS_A_PARTIR_DE = Decimal("200")


def para_json(valor):
    """O DynamoDB devolve números como Decimal; o JSON quer int ou float."""
    if isinstance(valor, Decimal):
        return int(valor) if valor == valor.to_integral_value() else float(valor)
    raise TypeError(f"não sei converter {type(valor).__name__}")


def resposta(status, dados):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json; charset=utf-8"},
        "body": json.dumps(dados, default=para_json, ensure_ascii=False),
    }


def corpo(event):
    """O JSON do pedido, com números como Decimal (o DynamoDB não aceita float)."""
    bruto = event.get("body") or "{}"
    if event.get("isBase64Encoded"):
        bruto = base64.b64decode(bruto).decode("utf-8")
    return json.loads(bruto, parse_float=Decimal)


def listar_produtos():
    itens = tabela.scan()["Items"]
    return resposta(200, sorted(itens, key=lambda p: p["id"]))


def buscar_produto(produto_id):
    try:
        chave = int(produto_id)
    except (TypeError, ValueError):
        return resposta(422, {"detail": "id deve ser um número"})
    item = tabela.get_item(Key={"id": chave}).get("Item")
    if item is None:
        return resposta(404, {"detail": "produto não encontrado"})
    return resposta(200, item)


def cadastrar_produto(dados):
    nome = str(dados.get("nome") or "").strip()
    preco = dados.get("preco")
    if not nome:
        return resposta(422, {"detail": "nome é obrigatório"})
    if not isinstance(preco, (int, Decimal)) or isinstance(preco, bool) or preco <= 0:
        return resposta(422, {"detail": "preço deve ser maior que zero"})
    if not isinstance(dados.get("id"), (int, Decimal)) or isinstance(dados.get("id"), bool):
        return resposta(422, {"detail": "id (número) é obrigatório"})

    item = {"id": int(dados["id"]), "nome": nome, "preco": Decimal(str(preco))}
    if dados.get("tamanho"):
        item["tamanho"] = str(dados["tamanho"])
    try:
        # só grava se ainda não existe item com esse id
        tabela.put_item(Item=item, ConditionExpression="attribute_not_exists(id)")
    except ClientError as erro:
        if erro.response["Error"]["Code"] == "ConditionalCheckFailedException":
            return resposta(409, {"detail": f"já existe produto com id {item['id']}"})
        raise
    return resposta(201, item)


def total_do_carrinho(dados):
    """{"itens": [{"produto_id": 1, "quantidade": 2}, ...]} -> total com promoção e frete.
    Os preços vêm do banco, nunca do cliente."""
    subtotal = Decimal("0")
    for linha in dados.get("itens", []):
        item = tabela.get_item(Key={"id": int(linha["produto_id"])}).get("Item")
        if item is None:
            return resposta(404, {"detail": f"produto {linha['produto_id']} não encontrado"})
        quantidade = int(linha.get("quantidade", 1))
        if not 0 < quantidade <= 10:
            return resposta(422, {"detail": "quantidade deve ser de 1 a 10"})
        subtotal += item["preco"] * quantidade
    com_desconto = subtotal * (1 - DESCONTO)
    frete = Decimal("0") if com_desconto >= FRETE_GRATIS_A_PARTIR_DE else FRETE_FIXO
    total = (com_desconto + frete).quantize(Decimal("0.01"))
    return resposta(200, {"subtotal": subtotal.quantize(Decimal("0.01")), "total": total})


def lambda_handler(event, context):
    cabecalhos = {k.lower(): v for k, v in (event.get("headers") or {}).items()}
    if cabecalhos.get("x-api-key") != os.environ["CHAVE_LOJA"]:
        return resposta(401, {"detail": "chave da API ausente ou inválida"})

    rota = event.get("routeKey", "")
    parametros = event.get("pathParameters") or {}
    try:
        if rota == "GET /produtos":
            return listar_produtos()
        if rota == "GET /produtos/{id}":
            return buscar_produto(parametros.get("id"))
        if rota == "POST /produtos":
            return cadastrar_produto(corpo(event))
        if rota == "POST /carrinho/total":
            return total_do_carrinho(corpo(event))
        if rota == "GET /promocoes":
            return resposta(200, PROMOCOES)
    except (json.JSONDecodeError, KeyError, ValueError) as erro:
        return resposta(400, {"detail": f"pedido inválido: {erro}"})
    return resposta(404, {"detail": f"rota não encontrada: {rota}"})
