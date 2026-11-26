# Aula 11 — A loja ganha um banco (DynamoDB)

## Tabela

| Item | Valor |
|---|---|
| Nome | `loja-produtos` |
| Chave de partição | `id` (Number) |
| Chave de ordenação | nenhuma |
| Capacidade | On-demand (`PAY_PER_REQUEST`) |
| Região | us-east-1 |

## Por que a chave é `id`

- **Toda leitura da loja é por produto**: `GET /produtos/{id}` e o carrinho buscam um
  produto pelo número. Com `id` como chave de partição, cada uma dessas buscas é um
  `GetItem`: uma leitura direta, rápida e barata, sem varrer a tabela.
- **É único e não muda.** O nome pode mudar (corrigir "Calça Jeans"), o preço muda toda
  semana. Uma chave não pode ser alterada no DynamoDB, então não pode ser um campo que
  muda.
- **Garante que não há duplicata.** `put_item` com
  `ConditionExpression="attribute_not_exists(id)"` só grava se o id é novo. Isso dá o
  409, sem precisar ler antes.
- **Espalha bem a carga.** Cada produto cai numa partição pelo hash do id, sem "chave
  quente". Com `tamanho` ou `tipo` como chave, poucos valores concentrariam tudo.
- **Por que não chave composta?** Não há consulta por intervalo dentro de um grupo (ex.:
  "pedidos de um cliente por data"). Uma chave simples basta. A listagem da vitrine usa
  `Scan`, que é aceitável com poucas dezenas de itens. Com milhares de itens, seria caso
  de paginação ou de um índice secundário.

## Permissão mínima

A política inline `loja-dynamodb` no `loja-api-role` libera só `GetItem`, `PutItem` e
`Scan`, e só na tabela `loja-produtos`. A Lambda não pode apagar itens nem a tabela,
nem mexer em outras tabelas (privilégio mínimo).

## Testes (CloudShell)

| Pedido | Esperado |
|---|---|
| `GET /produtos/2` | 200 |
| `GET /produtos/9` | 404 |
| `POST /produtos` id 4 Boné 49.9 | 201 |
| o mesmo POST de novo | 409 |

A tabela **fica ligada**: as aulas 12 e 13 usam ela.
