"""Etapa 22: a API confia só na vitrine da porta 5500 (Aula 13)."""
from fastapi.testclient import TestClient

from api import app

cliente = TestClient(app)


def test_vitrine_da_porta_5500_pode_ler():
    resposta = cliente.get("/", headers={"Origin": "http://127.0.0.1:5500"})
    assert resposta.headers["access-control-allow-origin"] == "http://127.0.0.1:5500"


def test_origem_estranha_nao_recebe_permissao():
    resposta = cliente.get("/", headers={"Origin": "http://site-estranho.com"})
    assert "access-control-allow-origin" not in resposta.headers
