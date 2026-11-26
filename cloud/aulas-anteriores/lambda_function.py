"""Pré-requisito (aulas anteriores): a Lambda loja-api com o catálogo em memória.

Na Aula 11 este código é trocado pelo de cloud/aula-11/lambda_function.py (DynamoDB).
Variável de ambiente: CHAVE_LOJA. Evento: API Gateway HTTP API, payload 2.0.
"""
import json
import os

PRODUTOS = [
    {"id": 1, "nome": "Camiseta básica", "preco": 39.90, "tamanho": "M"},
    {"id": 2, "nome": "Calça jeans", "preco": 129.90, "tamanho": "G"},
    {"id": 3, "nome": "Moletom", "preco": 159.90, "tamanho": "P"},
]
PROMOCOES = [{"nome": "Semana da loja", "desconto": "10% em tudo",
              "frete_gratis_a_partir_de": 200}]


def resposta(status, dados):
    return {"statusCode": status,
            "headers": {"Content-Type": "application/json; charset=utf-8"},
            "body": json.dumps(dados, ensure_ascii=False)}


def lambda_handler(event, context):
    cabecalhos = {k.lower(): v for k, v in (event.get("headers") or {}).items()}
    if cabecalhos.get("x-api-key") != os.environ["CHAVE_LOJA"]:
        return resposta(401, {"detail": "chave da API ausente ou inválida"})

    rota = event.get("routeKey", "")
    if rota == "GET /produtos":
        return resposta(200, PRODUTOS)
    if rota == "GET /produtos/{id}":
        produto_id = (event.get("pathParameters") or {}).get("id", "")
        for p in PRODUTOS:
            if str(p["id"]) == produto_id:
                return resposta(200, p)
        return resposta(404, {"detail": "produto não encontrado"})
    if rota == "GET /promocoes":
        return resposta(200, PROMOCOES)
    if rota == "POST /carrinho/total":
        dados = json.loads(event.get("body") or "{}")
        precos = {p["id"]: p["preco"] for p in PRODUTOS}
        subtotal = sum(precos[i["produto_id"]] * i.get("quantidade", 1) for i in dados.get("itens", []))
        com_desconto = subtotal * 0.9
        frete = 0 if com_desconto >= 200 else 15
        return resposta(200, {"subtotal": round(subtotal, 2), "total": round(com_desconto + frete, 2)})
    return resposta(404, {"detail": f"rota não encontrada: {rota}"})
