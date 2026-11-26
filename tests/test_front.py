"""Etapa 16: o HTML da vitrine é semântico e acessível (Aula 11)."""
from html.parser import HTMLParser
from pathlib import Path

import pytest

FRONT = Path(__file__).parent.parent / "front"
PAGINAS = ["index.html", "cadastro.html"]


class Leitor(HTMLParser):
    """Anota cada tag aberta e seus atributos."""

    def __init__(self):
        super().__init__()
        self.tags = []          # [(nome, {atributos})]

    def handle_starttag(self, tag, attrs):
        self.tags.append((tag, dict(attrs)))

    def todas(self, nome):
        return [a for t, a in self.tags if t == nome]


def ler(pagina):
    leitor = Leitor()
    leitor.feed((FRONT / pagina).read_text(encoding="utf-8"))
    return leitor


@pytest.mark.parametrize("pagina", PAGINAS)
def test_tem_as_tags_semanticas(pagina):
    leitor = ler(pagina)
    assert leitor.todas("html")[0].get("lang") == "pt-BR"
    for tag in ("header", "nav", "main", "footer", "h1"):
        assert leitor.todas(tag), f"falta <{tag}> em {pagina}"
    assert len(leitor.todas("main")) == 1


@pytest.mark.parametrize("pagina", PAGINAS)
def test_toda_imagem_tem_alt(pagina):
    for img in ler(pagina).todas("img"):
        assert img.get("alt"), f"imagem sem alt: {img.get('src')}"


@pytest.mark.parametrize("pagina", PAGINAS)
def test_todo_campo_tem_label(pagina):
    leitor = ler(pagina)
    ligados = {label.get("for") for label in leitor.todas("label")}
    campos = leitor.todas("input") + leitor.todas("select") + leitor.todas("textarea")
    for campo in campos:
        if campo.get("type") in ("hidden", "submit", "button"):
            continue
        assert campo.get("id") in ligados or campo.get("aria-label"), \
            f"campo sem label: {campo}"


def test_cadastro_tem_os_campos_do_post():
    """Os name do formulário são os campos do POST /produtos."""
    leitor = ler("cadastro.html")
    campos = leitor.todas("input") + leitor.todas("select")
    assert {c.get("name") for c in campos} == {"tipo", "nome", "preco", "tamanho"}


def test_preco_e_nome_tem_regras():
    leitor = ler("cadastro.html")
    por_id = {c.get("id"): c for c in leitor.todas("input")}
    assert "required" in por_id["nome"]
    preco = por_id["preco"]
    assert preco.get("type") == "number"
    assert preco.get("min") == "0.01" and preco.get("step") == "0.01"
    assert "required" in preco
