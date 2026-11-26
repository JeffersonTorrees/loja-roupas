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
  // o contrato da API; na Lambda da Cloud o tamanho é opcional
  tamanho.textContent = p.tamanho ? `Tamanho ${p.tamanho}` : "Tamanho único";

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

// Etapa 24: a pessoa sempre sabe o que está acontecendo
const estado = document.querySelector("#estado");

async function carregar() {
  estado.textContent = "Carregando produtos...";
  try {
    const resposta = await fetch(`${API}/produtos`, { headers: API_HEADERS });
    if (!resposta.ok) {
      throw new Error(`a API respondeu ${resposta.status}`);
    }
    produtos = await resposta.json();
    desenhar(produtos);
    estado.textContent = produtos.length === 0 ? "Nenhum produto cadastrado ainda." : "";
  } catch (erro) {
    estado.textContent = "Não foi possível falar com a API. Ela está ligada?";
    console.error(erro);
  }
}

busca.addEventListener("input", (e) => {
  const termo = e.target.value.trim().toLowerCase();
  const achados = produtos.filter((p) => p.nome.toLowerCase().includes(termo));
  desenhar(achados);
});

carregar();
