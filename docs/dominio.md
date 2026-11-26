# Diagrama de domínio (rascunho)

As classes que representam o negócio da loja (`loja/produto.py`, `loja/carrinho.py`,
`loja/promocao.py`). Nenhuma delas sabe de HTTP ou de banco.

```mermaid
classDiagram
    class Produto {
        +str nome
        +float preco
        +str tamanho
        +descricao() str
        +para_dict() dict
    }
    class Camiseta {
        +str manga
    }
    class Calca {
        +str modelagem
    }
    class Carrinho {
        +adicionar(produto, quantidade)
        +itens
        +quantidade_de_pecas
        +subtotal
        +total
    }
    class Promocao {
        <<abstract>>
        +aplicar(subtotal) float
    }
    class SemPromocao
    class Percentual {
        +pct
    }
    class Cupom {
        +valor
    }

    Produto <|-- Camiseta : é um
    Produto <|-- Calca : é um
    Carrinho o-- "0..*" Produto : tem
    Carrinho --> "1" Promocao : usa
    Promocao <|.. SemPromocao
    Promocao <|.. Percentual
    Promocao <|.. Cupom
```

## Regras que o domínio garante

- Nome não pode ser vazio; preço tem que ser maior que zero.
- Tamanho só pode ser PP, P, M, G ou GG.
- Camiseta tem manga `curta` ou `longa`; Calça tem modelagem.
- Frete grátis a partir de R$ 200 (em `loja/calculos.py`); a promoção da semana é `Percentual(10)`.
