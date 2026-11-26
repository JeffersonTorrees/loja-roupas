"""Etapa 13: o repositório, a única camada que conversa com o banco (Aula 10)."""
from sqlmodel import select

from loja.banco import ProdutoRegistro
from loja.produto import Calca, Camiseta, Produto

CAMPOS = ("tipo", "nome", "preco", "tamanho", "manga", "modelagem")


def para_dominio(registro):
    """Linha do banco -> objeto do domínio (Produto, Camiseta ou Calca)."""
    if registro.tipo == "Camiseta":
        return Camiseta(registro.nome, registro.preco, registro.tamanho, registro.manga)
    if registro.tipo == "Calca":
        return Calca(registro.nome, registro.preco, registro.tamanho, registro.modelagem)
    return Produto(registro.nome, registro.preco, registro.tamanho)


def para_registro(produto):
    """Objeto do domínio -> linha do banco."""
    return ProdutoRegistro(**produto.para_dict())


class RepositorioProdutos:
    def __init__(self, sessao):
        self.sessao = sessao

    def adicionar(self, produto):
        registro = para_registro(produto)
        self.sessao.add(registro)
        self.sessao.commit()
        self.sessao.refresh(registro)
        return registro.id

    def buscar(self, produto_id):
        registro = self.sessao.get(ProdutoRegistro, produto_id)
        if registro is None:
            return None
        return para_dominio(registro)

    def existe_nome(self, nome, exceto_id=None):
        consulta = select(ProdutoRegistro).where(ProdutoRegistro.nome == nome)
        if exceto_id is not None:
            consulta = consulta.where(ProdutoRegistro.id != exceto_id)
        return self.sessao.exec(consulta).first() is not None

    def listar(self, tamanho=None, preco_max=None):
        consulta = select(ProdutoRegistro)
        if tamanho is not None:
            consulta = consulta.where(ProdutoRegistro.tamanho == tamanho)
        if preco_max is not None:
            consulta = consulta.where(ProdutoRegistro.preco <= preco_max)
        consulta = consulta.order_by(ProdutoRegistro.id)
        return [(r.id, para_dominio(r)) for r in self.sessao.exec(consulta)]

    def atualizar(self, produto_id, produto):
        registro = self.sessao.get(ProdutoRegistro, produto_id)
        if registro is None:
            return False
        novos = produto.para_dict()
        for campo in CAMPOS:
            setattr(registro, campo, novos.get(campo))
        self.sessao.add(registro)
        self.sessao.commit()
        return True

    def remover(self, produto_id):
        registro = self.sessao.get(ProdutoRegistro, produto_id)
        if registro is None:
            return False
        self.sessao.delete(registro)
        self.sessao.commit()
        return True
