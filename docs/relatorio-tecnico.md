# Relatório técnico — Loja de Roupas (rascunho)

**Disciplina:** Coding · Faculdade Senac Pernambuco · ADS 2026.2

**Equipe:** Jefferson dos Santos Torres (trabalho individual)

## 1. O problema

Uma loja de roupas precisa de um catálogo que a equipe consiga cadastrar e alterar,
e de uma vitrine onde o cliente veja os produtos. Até a Aula 9 o catálogo vivia na
memória: reiniciar o servidor apagava tudo.

## 2. A solução

- **API REST** em FastAPI (`api.py`) com CRUD de produtos e um carrinho.
- **Banco SQLite** (`loja.db`) com SQLModel: os dados sobrevivem ao reinício.
- **Camadas**: rota → serviço → repositório → banco (ver [arquitetura.md](arquitetura.md)).
- **Front** em HTML semântico + CSS (Flexbox/Grid) + JavaScript puro (`front/`), que
  conversa com a API por `fetch`.

## 3. Decisões e por quê

| Decisão | Por quê |
|---|---|
| SQLite | um arquivo, zero instalação; suficiente para uma loja pequena |
| Uma tabela com coluna `tipo` | Camiseta e Calça diferem em 1 campo; evita JOIN ([modelo-er.md](modelo-er.md)) |
| Serviço sem HTTP nem banco | regras testáveis sozinhas; trocar o banco não mexe nas regras |
| Repositório recebe a sessão | os testes injetam um banco em memória (`engine_em_memoria`) |
| Exceções do domínio → status HTTP | a rota fica fina; 404/409/422 num lugar só |
| CORS só para a porta 5500 | o navegador só libera quem a API conhece; nunca `*` |
| `config.js` com `/api` em produção | no servidor, nginx serve front e API na mesma origem: sem CORS |
| `createElement` + `textContent` | dado vindo da API nunca vira HTML (evita XSS) |

## 4. Qualidade

- **68 testes** com pytest: domínio, repositório, serviço, API (TestClient), CORS e HTML
  (tags semânticas, `alt`, `label`).
- **GitHub Actions** roda os testes a cada push.
- Acessibilidade: `lang`, landmarks (`header`/`nav`/`main`/`footer`), `label for`,
  `role="status"` nos avisos, foco visível. Conferido no W3C e no Lighthouse _(anexar)_.

## 5. Limitações e próximos passos

- O carrinho ainda é um só e fica na memória (compartilhado entre clientes).
- Não há login: qualquer pessoa pode cadastrar ou apagar produtos.
- SQLite não aguenta muitos escritores ao mesmo tempo; para crescer, PostgreSQL
  (só o `URL_BANCO` muda, graças às camadas).
- Deploy: EC2 + nginx + uvicorn (ver README, seção "Deploy na AWS").
