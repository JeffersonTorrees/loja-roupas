// Etapas 19 a 22: a vitrine desenhada por JavaScript, agora com os produtos da API
// (a constante API vem do config.js)
let produtos = [];          // agora vem da API

const vitrine = document.querySelector("#vitrine");
const busca = document.querySelector("#busca");

function montarCard(p) {
  const card = document.createElement("article");
  card.className = "produto";

  const titulo = document.createElement("h3");
  titulo.textContent = p.nome;

  const tamanho = document.createElement("p");
  tamanho.textContent = `Tamanho ${p.tamanho}`;   // o contrato da API

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

async function carregar() {
  const resposta = await fetch(`${API}/produtos`);
  produtos = await resposta.json();
  desenhar(produtos);
}

busca.addEventListener("input", (e) => {
  const termo = e.target.value.trim().toLowerCase();
  const achados = produtos.filter((p) => p.nome.toLowerCase().includes(termo));
  desenhar(achados);
});

carregar();
