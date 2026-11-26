# Arquitetura em camadas (rascunho)

Cada camada só conversa com a de baixo. Quem está em cima não sabe *como* a de baixo
funciona: o serviço não sabe que o banco é SQLite; a rota não sabe que existe SQL.

```mermaid
flowchart TB
    subgraph Navegador
        HTML["index.html / cadastro.html"]
        JS["app.js / cadastro.js<br/>(fetch)"]
    end
    subgraph Servidor["Servidor (FastAPI)"]
        ROTA["api.py<br/>rotas HTTP, Pydantic, CORS,<br/>exceção → status"]
        SERV["loja/servico.py<br/>ServicoCatalogo: regras"]
        DOM["loja/produto.py<br/>domínio"]
        REPO["loja/repositorio.py<br/>RepositorioProdutos"]
        BANCO["loja/banco.py<br/>SQLModel / engine"]
    end
    DB[("loja.db<br/>SQLite")]

    HTML --> JS
    JS -- "HTTP + JSON" --> ROTA
    ROTA --> SERV
    SERV --> DOM
    SERV --> REPO
    REPO --> BANCO
    BANCO --> DB
```

## A viagem de um GET

`GET /produtos` saindo da vitrine e voltando como cartões na tela:

```mermaid
sequenceDiagram
    autonumber
    participant N as Navegador (app.js)
    participant A as api.py (rota)
    participant S as ServicoCatalogo
    participant R as RepositorioProdutos
    participant D as loja.db

    N->>A: fetch(API + "/produtos"), rede, HTTP GET
    A->>A: Depends: abre Session, monta serviço
    A->>S: listar(tamanho, preco_max)
    S->>R: listar(...)
    R->>D: SELECT * FROM produto ORDER BY id
    D-->>R: linhas (ProdutoRegistro)
    R-->>S: [(id, Camiseta/Calca/Produto)] (para_dominio)
    S-->>A: [{id, tipo, nome, preco, tamanho, ...}] (com_id)
    A-->>N: 200 OK + JSON (com cabeçalho CORS)
    N->>N: resposta.json() → desenhar() → <article> na #vitrine
```

Se algo dá errado no caminho, o serviço levanta uma exceção do domínio
(`ProdutoNaoEncontrado`, `ProdutoJaExiste`, `DadosInvalidos`) e o `api.py` a traduz
para 404, 409 ou 422. Se a API nem responde, o `catch` do `app.js` mostra
"Não foi possível falar com a API. Ela está ligada?".
