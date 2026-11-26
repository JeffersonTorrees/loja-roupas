# Aula 12 — A loja ganha rede (VPC `loja-vpc`, 10.0.0.0/16)

```mermaid
flowchart TB
    INTERNET(("Internet"))
    APIGW["API Gateway HTTP<br/>loja-api"]
    DDB[("DynamoDB<br/>loja-produtos")]
    S3[("S3")]

    subgraph VPC["loja-vpc 10.0.0.0/16 (us-east-1)"]
        IGW["loja-igw<br/>Internet Gateway"]
        subgraph AZA["us-east-1a"]
            PUB1["loja-subnet-public1<br/>10.0.0.0/20"]
            PRIV1["loja-subnet-private1<br/>10.0.128.0/20<br/>ENI da Lambda"]
        end
        subgraph AZB["us-east-1b"]
            PUB2["loja-subnet-public2<br/>10.0.16.0/20"]
            PRIV2["loja-subnet-private2<br/>10.0.144.0/20<br/>ENI da Lambda"]
        end
        RTPUB["loja-rtb-public<br/>10.0.0.0/16 local<br/>0.0.0.0/0 → igw"]
        RTPRIV["loja-rtb-private1 / private2<br/>10.0.0.0/16 local<br/>pl-s3 → vpce-s3<br/>pl-dynamodb → vpce-dynamodb"]
        VPCE_S3["loja-vpce-s3<br/>(Gateway)"]
        VPCE_DDB["loja-vpce-dynamodb<br/>(Gateway)"]
        SG["loja-lambda-sg<br/>entrada: nada · saída: tudo"]
    end

    INTERNET --- IGW
    IGW --- RTPUB
    RTPUB --- PUB1 & PUB2
    APIGW -- invoca --> LAMBDA["Lambda loja-api"]
    LAMBDA -. ENIs .- PRIV1 & PRIV2
    SG -. protege .- LAMBDA
    PRIV1 & PRIV2 --- RTPRIV
    RTPRIV --> VPCE_DDB --> DDB
    RTPRIV --> VPCE_S3 --> S3
```

**Não há NAT Gateway.** As sub-redes privadas não têm rota para a internet. Elas só
alcançam a própria VPC e, pelos endpoints Gateway (gratuitos), o S3 e o DynamoDB.

## Por que existe cada peça pública

| Peça | Justificativa |
|---|---|
| `loja-igw` (Internet Gateway) | é a porta da VPC para a internet; sem ele nada na VPC fala com fora. Hoje só as sub-redes públicas o usam. |
| `loja-subnet-public1/2` | reservam espaço, em 2 AZs, para o que precisa ser alcançado da internet (um load balancer ou um bastion no futuro). A Lambda **não** fica nelas. |
| `loja-rtb-public` | a única tabela com `0.0.0.0/0 → igw`; é ela que torna uma sub-rede "pública". |
| API Gateway (fora da VPC) | é o único ponto de entrada público da loja; recebe HTTPS e invoca a Lambda, que fica escondida nas privadas. |

## O que aconteceu nos testes

1. Lambda nas privadas, sem endpoint do DynamoDB: o `boto3` tenta
   `dynamodb.us-east-1.amazonaws.com`, mas não há rota. Resultado: "Task timed out
   after 3.00 seconds", e o API Gateway responde **502**.
2. Com o `loja-vpce-dynamodb` nas 2 tabelas privadas, a rota `pl-… → vpce-…` leva o
   tráfego ao DynamoDB pela rede da AWS, sem internet. Resultado: **200 / 404 / 201 / 409**.
