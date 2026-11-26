"""Etapa 13: o banco de dados da loja (Aula 10).

O catálogo sai da memória e vai para um arquivo SQLite (loja.db).
"""
from sqlalchemy.pool import StaticPool
from sqlmodel import Field, SQLModel, create_engine

URL_BANCO = "sqlite:///loja.db"


class ProdutoRegistro(SQLModel, table=True):
    """Uma linha da tabela produto: o produto como o banco guarda."""
    __tablename__ = "produto"

    id: int | None = Field(default=None, primary_key=True)
    tipo: str
    nome: str = Field(unique=True)
    preco: float
    tamanho: str
    manga: str | None = None
    modelagem: str | None = None


def criar_engine(url=URL_BANCO):
    """A conexão com o banco. O SQLite precisa de check_same_thread=False
    porque o FastAPI atende pedidos em threads diferentes."""
    argumentos = {"check_same_thread": False} if url.startswith("sqlite") else {}
    return create_engine(url, connect_args=argumentos)


def engine_em_memoria():
    """Banco que vive só na memória: ótimo para testes (começa vazio)."""
    return create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )


def criar_tabelas(engine):
    SQLModel.metadata.create_all(engine)
