# Aula 13 — Concorrência e custo

## Lei de Little: quantas execuções ao mesmo tempo?

> **concorrência = taxa de chegada × tempo de cada execução**

| Cenário | Taxa (pedidos/s) | Duração | Concorrência |
|---|---:|---:|---:|
| `loja-pedidos` (só põe na fila) | 20 | 0,2 s | 20 × 0,2 = **4** |
| se o pedido fosse processado **na hora** (sem fila) | 20 | 4 s | 20 × 4 = **80** |

**Com cota de 10 execuções simultâneas** (conta nova), o processamento síncrono precisaria
de 80. A partir da **11ª** execução simultânea, a Lambda responde *throttle* (429), e o
cliente vê erro: **pedido perdido**.

Com a fila, o recebimento precisa de só 4 execuções. O trabalho pesado (`loja-processa`)
fica limitado a **2 simultâneas** (maximum concurrency do gatilho). O excesso **espera na
fila** em vez de ser rejeitado. A fila funciona como amortecedor: no pico ela cresce e
depois esvazia, como aparece no Monitoring.

Tempo para esvaziar o teste de carga: 100 mensagens × 1 s ÷ 2 em paralelo ≈ **50 s**
(mais o overhead de polling).

## DLQ: quando um pedido "morre"

`maxReceiveCount = 3`: a mensagem é entregue 3 vezes. Com `VisibilityTimeout = 30 s`, isso
leva cerca de 1–1,5 minuto. Depois ela vai para a `loja-pedidos-dlq`. O alarme
`loja-pedido-perdido` (Maximum de `ApproximateNumberOfMessagesVisible` > 0 em 1 minuto)
dispara o e-mail pelo SNS `loja-alertas`.

## Estimativa de custo (us-east-1, preços públicos, sem nível gratuito)

Premissas: cada pedido = 1 `POST /pedidos` (API Gateway HTTP) + `loja-pedidos` (128 MB,
~0,2 s) + 3 requisições SQS (send, receive, delete) + `loja-processa` (128 MB, ~1 s).

| Item | Preço |
|---|---|
| API Gateway HTTP | US$ 1,00 por milhão de requisições |
| Lambda requisições | US$ 0,20 por milhão |
| Lambda duração | US$ 0,0000166667 por GB-s |
| SQS Standard | US$ 0,40 por milhão de requisições |
| CloudWatch alarme | US$ 0,10 por alarme/mês |
| SNS e-mail | 1.000 grátis/mês, depois US$ 2 por 100 mil |

**Por pedido:** API 0,000001 + Lambda req 2 × 0,0000002 + duração (0,128 GB × 1,2 s ×
0,0000166667 ≈ 0,00000256) + SQS 3 × 0,0000004 ≈ **US$ 0,0000052**
(cerca de US$ 5 por milhão de pedidos).

| Cenário | Pedidos/mês | Custo aproximado |
|---|---:|---:|
| Dia normal: 2.000 pedidos/dia | 60.000 | 60.000 × 0,0000052 ≈ **US$ 0,31** + alarme 0,10 = **US$ 0,41/mês** |
| Pico (Black Friday): 20 pedidos/s por 2 h no dia | +144.000 | +US$ 0,75 nesse dia |

No nível gratuito (1 milhão de requisições Lambda e SQS por mês, 400 mil GB-s), o custo da
turma é praticamente **zero**: só o alarme, US$ 0,10/mês. O ponto principal: o custo
**acompanha o uso**. No pico ele sobe, sem servidor ocioso pago no resto do mês.
