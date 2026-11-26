"""Etapa 14: o serviço do catálogo, onde moram as regras (Aula 10).

Só conhece o domínio: não sabe nada de HTTP nem de banco.
O repositório chega pronto de fora (injeção de dependência).
"""
from loja.produto import Calca, Camiseta, Produto


class ProdutoNaoEncontrado(Exception):
    pass


class ProdutoJaExiste(Exception):
    pass


class DadosInvalidos(Exception):
    pass


def criar_produto(dados):
    """Dicionário (o que chegou do cliente) -> objeto do domínio."""
    tipo = dados.get("tipo") or "Produto"
    try:
        if tipo == "Camiseta":
            return Camiseta(dados["nome"], dados["preco"], dados["tamanho"], dados.get("manga"))
        if tipo == "Calca":
            if not dados.get("modelagem"):
                raise DadosInvalidos("calça precisa de modelagem")
            return Calca(dados["nome"], dados["preco"], dados["tamanho"], dados["modelagem"])
        if tipo == "Produto":
            return Produto(dados["nome"], dados["preco"], dados["tamanho"])
    except (ValueError, KeyError) as erro:
        raise DadosInvalidos(f"dados inválidos: {erro}") from erro
    raise DadosInvalidos(f"tipo desconhecido: {tipo}")


def com_id(produto_id, produto):
    return {"id": produto_id, **produto.para_dict()}


class ServicoCatalogo:
    def __init__(self, repositorio):
        self.repositorio = repositorio

    def listar(self, tamanho=None, preco_max=None):
        return [com_id(i, p) for i, p in self.repositorio.listar(tamanho, preco_max)]

    def produto(self, produto_id):
        """O objeto do domínio (o carrinho precisa dele)."""
        produto = self.repositorio.buscar(produto_id)
        if produto is None:
            raise ProdutoNaoEncontrado("produto não encontrado")
        return produto

    def buscar(self, produto_id):
        return com_id(produto_id, self.produto(produto_id))

    def cadastrar(self, dados):
        produto = criar_produto(dados)
        if self.repositorio.existe_nome(produto.nome):
            raise ProdutoJaExiste(f"já existe um produto chamado {produto.nome}")
        produto_id = self.repositorio.adicionar(produto)
        return com_id(produto_id, produto)

    def atualizar(self, produto_id, dados):
        self.produto(produto_id)   # confere se existe (senão 404)
        produto = criar_produto(dados)
        if self.repositorio.existe_nome(produto.nome, exceto_id=produto_id):
            raise ProdutoJaExiste(f"já existe um produto chamado {produto.nome}")
        self.repositorio.atualizar(produto_id, produto)
        return com_id(produto_id, produto)

    def remover(self, produto_id):
        if not self.repositorio.remover(produto_id):
            raise ProdutoNaoEncontrado("produto não encontrado")
