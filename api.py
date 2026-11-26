"""Etapas 10 a 15: a loja como API, agora com banco e camadas (Aulas 9 e 10).

Camadas: rota (aqui) -> serviço (loja/servico.py) -> repositório
(loja/repositorio.py) -> banco (loja/banco.py, arquivo loja.db).
"""
from contextlib import asynccontextmanager
from typing import Literal

from fastapi import Depends, FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from sqlmodel import Session

from loja.banco import criar_engine, criar_tabelas
from loja.carrinho import Carrinho
from loja.promocao import Percentual
from loja.repositorio import RepositorioProdutos
from loja.servico import (DadosInvalidos, ProdutoJaExiste, ProdutoNaoEncontrado,
                          ServicoCatalogo, com_id)

engine = criar_engine()

CATALOGO_INICIAL = [
    {"tipo": "Camiseta", "nome": "Camiseta básica", "preco": 39.90, "tamanho": "M", "manga": "curta"},
    {"tipo": "Calca", "nome": "Calça jeans", "preco": 129.90, "tamanho": "G", "modelagem": "reta"},
    {"tipo": "Produto", "nome": "Moletom", "preco": 159.90, "tamanho": "P"},
]


def popular_se_vazio(servico):
    """Na primeira vez, a loja já abre com os 3 produtos de sempre."""
    if not servico.listar():
        for dados in CATALOGO_INICIAL:
            servico.cadastrar(dados)


@asynccontextmanager
async def ciclo_de_vida(app):
    criar_tabelas(engine)
    with Session(engine) as sessao:
        popular_se_vazio(ServicoCatalogo(RepositorioProdutos(sessao)))
    yield


app = FastAPI(title="Loja de Roupas", lifespan=ciclo_de_vida)

# Etapa 22: o navegador só deixa a vitrine (porta 5500) ler a API (porta 8000)
# se a API disser que confia nessa origem. Nunca "*" nas origens.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://127.0.0.1:5500", "http://localhost:5500"],
    allow_methods=["*"],
    allow_headers=["*"],
)


def obter_sessao():
    with Session(engine) as sessao:
        yield sessao


def obter_servico(sessao: Session = Depends(obter_sessao)):
    return ServicoCatalogo(RepositorioProdutos(sessao))


# erros do serviço viram respostas HTTP
@app.exception_handler(ProdutoNaoEncontrado)
def nao_encontrado(request: Request, erro: ProdutoNaoEncontrado):
    return JSONResponse(status_code=404, content={"detail": str(erro)})


@app.exception_handler(ProdutoJaExiste)
def ja_existe(request: Request, erro: ProdutoJaExiste):
    return JSONResponse(status_code=409, content={"detail": str(erro)})


@app.exception_handler(DadosInvalidos)
def dados_invalidos(request: Request, erro: DadosInvalidos):
    return JSONResponse(status_code=422, content={"detail": str(erro)})


class ProdutoEntrada(BaseModel):
    """O formato que o cliente manda para cadastrar ou alterar um produto."""
    tipo: Literal["Produto", "Camiseta", "Calca"] = "Produto"
    nome: str
    preco: float
    tamanho: str
    manga: str | None = None
    modelagem: str | None = None


class ItemPedido(BaseModel):
    """O formato que o cliente precisa mandar no POST do carrinho."""
    produto_id: int
    quantidade: int = Field(gt=0, le=10)


def novo_carrinho():
    return Carrinho(Percentual(10))   # promoção da semana: 10%


# o carrinho continua na memória do servidor
carrinho = novo_carrinho()


@app.get("/")
def inicio():
    return {"loja": "Loja de Roupas", "documentacao": "/docs"}


@app.get("/produtos")
def listar_produtos(tamanho: str | None = None, preco_max: float | None = None,
                    servico: ServicoCatalogo = Depends(obter_servico)):
    return servico.listar(tamanho, preco_max)


@app.get("/produtos/{produto_id}")
def buscar_produto(produto_id: int, servico: ServicoCatalogo = Depends(obter_servico)):
    return servico.buscar(produto_id)


@app.post("/produtos", status_code=201)
def cadastrar_produto(entrada: ProdutoEntrada,
                      servico: ServicoCatalogo = Depends(obter_servico)):
    return servico.cadastrar(entrada.model_dump())


@app.put("/produtos/{produto_id}")
def atualizar_produto(produto_id: int, entrada: ProdutoEntrada,
                      servico: ServicoCatalogo = Depends(obter_servico)):
    return servico.atualizar(produto_id, entrada.model_dump())


@app.delete("/produtos/{produto_id}", status_code=204)
def remover_produto(produto_id: int, servico: ServicoCatalogo = Depends(obter_servico)):
    servico.remover(produto_id)


@app.post("/carrinho/itens", status_code=201)
def adicionar_item(item: ItemPedido, servico: ServicoCatalogo = Depends(obter_servico)):
    produto = servico.produto(item.produto_id)   # 404 se não existe
    carrinho.adicionar(produto, item.quantidade)
    return {
        "adicionado": com_id(item.produto_id, produto),
        "quantidade": item.quantidade,
        "pecas_no_carrinho": carrinho.quantidade_de_pecas,
    }


@app.get("/carrinho/total")
def total_do_carrinho():
    return {
        "pecas": carrinho.quantidade_de_pecas,
        "subtotal": round(carrinho.subtotal, 2),
        "total": round(carrinho.total, 2),   # com promoção e frete
    }


@app.delete("/carrinho", status_code=204)
def esvaziar_carrinho():
    global carrinho
    carrinho = novo_carrinho()
