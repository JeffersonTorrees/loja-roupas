import pytest
from sqlmodel import Session

from loja.banco import criar_tabelas, engine_em_memoria
from loja.repositorio import RepositorioProdutos
from loja.servico import (DadosInvalidos, ProdutoJaExiste, ProdutoNaoEncontrado,
                          ServicoCatalogo)

MOLETOM = {"nome": "Moletom", "preco": 159.90, "tamanho": "P"}


@pytest.fixture
def servico():
    engine = engine_em_memoria()
    criar_tabelas(engine)
    with Session(engine) as sessao:
        yield ServicoCatalogo(RepositorioProdutos(sessao))


def test_cadastrar_devolve_com_id(servico):
    criado = servico.cadastrar(MOLETOM)
    assert criado["id"] == 1
    assert criado["tipo"] == "Produto"


def test_nome_repetido_da_produto_ja_existe(servico):
    servico.cadastrar(MOLETOM)
    with pytest.raises(ProdutoJaExiste):
        servico.cadastrar(MOLETOM)


def test_preco_zero_da_dados_invalidos(servico):
    with pytest.raises(DadosInvalidos):
        servico.cadastrar({**MOLETOM, "preco": 0})


def test_tipo_desconhecido_da_dados_invalidos(servico):
    with pytest.raises(DadosInvalidos):
        servico.cadastrar({**MOLETOM, "tipo": "Sapato"})


def test_calca_sem_modelagem_da_dados_invalidos(servico):
    with pytest.raises(DadosInvalidos):
        servico.cadastrar({**MOLETOM, "tipo": "Calca"})


def test_buscar_inexistente_da_nao_encontrado(servico):
    with pytest.raises(ProdutoNaoEncontrado):
        servico.buscar(99)


def test_atualizar_mantem_o_nome_e_remover(servico):
    criado = servico.cadastrar(MOLETOM)
    alterado = servico.atualizar(criado["id"], {**MOLETOM, "preco": 99.90})
    assert alterado["preco"] == 99.90
    servico.remover(criado["id"])
    with pytest.raises(ProdutoNaoEncontrado):
        servico.remover(criado["id"])
