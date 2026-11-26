import pytest
from sqlmodel import Session

from loja.banco import criar_engine, criar_tabelas, engine_em_memoria
from loja.produto import Calca, Camiseta, Produto
from loja.repositorio import RepositorioProdutos


@pytest.fixture
def repo():
    engine = engine_em_memoria()
    criar_tabelas(engine)
    with Session(engine) as sessao:
        yield RepositorioProdutos(sessao)


def test_adicionar_e_buscar_devolve_o_mesmo_tipo(repo):
    produto_id = repo.adicionar(Camiseta("Camiseta básica", 39.90, "M", "curta"))
    achado = repo.buscar(produto_id)
    assert isinstance(achado, Camiseta)
    assert achado.manga == "curta"


def test_buscar_inexistente_devolve_none(repo):
    assert repo.buscar(99) is None


def test_listar_com_filtros_em_ordem_de_id(repo):
    repo.adicionar(Camiseta("Camiseta básica", 39.90, "M", "curta"))
    repo.adicionar(Calca("Calça jeans", 129.90, "G", "reta"))
    repo.adicionar(Produto("Moletom", 159.90, "P"))
    assert [p.nome for _, p in repo.listar()] == ["Camiseta básica", "Calça jeans", "Moletom"]
    assert [p.nome for _, p in repo.listar(tamanho="G")] == ["Calça jeans"]
    assert [p.nome for _, p in repo.listar(preco_max=130)] == ["Camiseta básica", "Calça jeans"]


def test_existe_nome_ignora_o_proprio_id(repo):
    produto_id = repo.adicionar(Produto("Moletom", 159.90, "P"))
    assert repo.existe_nome("Moletom")
    assert not repo.existe_nome("Moletom", exceto_id=produto_id)


def test_atualizar_e_remover(repo):
    produto_id = repo.adicionar(Produto("Moletom", 159.90, "P"))
    assert repo.atualizar(produto_id, Produto("Moletom", 149.90, "G"))
    assert repo.buscar(produto_id).preco == 149.90
    assert repo.remover(produto_id)
    assert repo.buscar(produto_id) is None
    assert not repo.atualizar(produto_id, Produto("Moletom", 1, "P"))
    assert not repo.remover(produto_id)


def test_dados_sobrevivem_ao_reinicio(tmp_path):
    url = f"sqlite:///{tmp_path / 'loja.db'}"
    engine = criar_engine(url)
    criar_tabelas(engine)
    with Session(engine) as sessao:
        produto_id = RepositorioProdutos(sessao).adicionar(Produto("Moletom", 159.90, "P"))
    engine.dispose()   # "desliga o servidor"

    outro = criar_engine(url)   # "liga de novo", mesmo arquivo
    with Session(outro) as sessao:
        achado = RepositorioProdutos(sessao).buscar(produto_id)
    outro.dispose()
    assert achado.nome == "Moletom"
