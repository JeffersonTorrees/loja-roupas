// Etapa 19: a vitrine desenhada por JavaScript (Aula 12)
const produtos = [
  { nome: "Camiseta básica", preco: 39.90, tam: "M" },
  { nome: "Calça jeans", preco: 129.90, tam: "G" },
  { nome: "Moletom", preco: 159.90, tam: "P" },
];

const vitrine = document.querySelector("#vitrine");

function montarCard(p) {
  const card = document.createElement("article");
  card.className = "produto";

  const titulo = document.createElement("h3");
  titulo.textContent = p.nome;

  const tamanho = document.createElement("p");
  tamanho.textContent = `Tamanho ${p.tam}`;

  const preco = document.createElement("p");
  const forte = document.createElement("strong");
  forte.textContent = `R$ ${p.preco.toFixed(2)}`;
  preco.append(forte);

  const botao = document.createElement("button");
  botao.type = "button";
  botao.textContent = "Pôr no carrinho";

  card.append(titulo, tamanho, preco, botao);
  return card;
}

function desenhar(lista) {
  vitrine.innerHTML = "";
  for (const p of lista) {
    vitrine.append(montarCard(p));
  }
}

desenhar(produtos);
