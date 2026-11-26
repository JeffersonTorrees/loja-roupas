# Aula 10 — Quanto a regra `logs-ciclo` economiza

**Cenário:** 500 GB de logs. Pela idade, 10% têm até 30 dias, 25% têm de 30 a 90 dias
e 65% têm mais de 90 dias.

**Preços (us-east-1, US$/GB/mês):** S3 Standard 0,023 · Standard-IA 0,0125 ·
Glacier Flexible Retrieval 0,0036.

## Sem regra (tudo em Standard)

500 GB × 0,023 = **US$ 11,50/mês**

## Com a regra (30 dias → IA, 90 dias → Glacier)

| Faixa | GB | Classe | Preço | Custo/mês |
|---|---:|---|---:|---:|
| até 30 dias (10%) | 50 | Standard | 0,023 | 1,150 |
| 30–90 dias (25%) | 125 | Standard-IA | 0,0125 | 1,5625 |
| mais de 90 dias (65%) | 325 | Glacier Flexible | 0,0036 | 1,170 |
| **Total** | **500** | | | **≈ US$ 3,88** |

## Economia

- 11,50 − 3,88 = **US$ 7,62/mês** (7,62 ÷ 11,50 ≈ **66%**)
- 7,62 × 12 = **US$ 91,44/ano**

## Decisão

Vale ligar a regra: logs quase nunca são lidos depois do primeiro mês, então pagar
Standard por eles é desperdício. Com a regra, a loja paga cerca de um terço, e os
logs com mais de 1 ano são apagados sozinhos. O custo é que ler um log antigo do
Glacier leva horas e é cobrado por GB. Para auditoria ocasional, isso é aceitável.

> Observação: a conta não inclui as taxas de transição (por requisição) nem a cobrança
> mínima de 30 dias do Standard-IA e de 90 dias do Glacier. Com arquivos de log
> grandes, essas taxas são pequenas perto da economia.
