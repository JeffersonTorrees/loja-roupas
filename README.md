# Loja de Roupas

![testes](https://github.com/JeffersonTorrees/loja-roupas/actions/workflows/testes.yml/badge.svg)

Projeto construído passo a passo na aula de Coding (Faculdade Senac Pernambuco, ADS 2026.2).

Uma loja de roupas como API REST (FastAPI). O catálogo fica gravado num banco
SQLite (`loja.db`), então os produtos sobrevivem quando o servidor reinicia. O código
é separado em camadas: **rota → serviço → repositório → banco**.

## Como rodar

```bash
git clone https://github.com/JeffersonTorrees/loja-roupas.git
cd loja-roupas
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt
pytest -v                        # todos os testes devem passar
fastapi dev api.py               # abre a API em http://127.0.0.1:8000/docs
```

Na primeira vez que a API sobe, ela cria o `loja.db` com 3 produtos. Apague o
arquivo para voltar ao catálogo inicial.

## Rotas

| Método | Rota | O que faz |
|---|---|---|
| GET | `/produtos?tamanho=M&preco_max=100` | lista (filtros opcionais) |
| GET | `/produtos/{id}` | um produto (404 se não existe) |
| POST | `/produtos` | cadastra (201; 409 nome repetido; 422 dados inválidos) |
| PUT | `/produtos/{id}` | altera |
| DELETE | `/produtos/{id}` | remove (204) |
| POST | `/carrinho/itens` | põe no carrinho (o carrinho fica na memória) |
| GET | `/carrinho/total` | total com promoção e frete |
| DELETE | `/carrinho` | esvazia o carrinho |

## O que tem aqui

| Pasta ou arquivo | O que é | Aula |
|---|---|---|
| `vitrine.py` | os dados da loja em listas e dicionários | 3 |
| `loja/calculos.py` | total do carrinho e frete, com testes | 4 |
| `loja/produto.py` | Produto, Camiseta e Calça (o domínio) | 6 e 7 |
| `loja/carrinho.py` | o Carrinho, que tem produtos e uma promoção | 6 e 7 |
| `loja/promocao.py` | o contrato Promocao e três promoções | 7 e 8 |
| `.github/workflows/testes.yml` | o GitHub roda os testes a cada push | 8 |
| `api.py` | as rotas HTTP (só traduz HTTP ↔ serviço) | 9 e 10 |
| `loja/banco.py` | tabela `produto` e conexão SQLite (SQLModel) | 10 |
| `loja/repositorio.py` | a única camada que fala com o banco | 10 |
| `loja/servico.py` | as regras do catálogo (sem HTTP, sem banco) | 10 |
| `tests/` | testes de cada camada | 4 a 10 |
