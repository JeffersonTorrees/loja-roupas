// Etapas 21 e 23: o formulário valida e grava no banco pelo POST (Aulas 12 e 13)
// (a constante API vem do config.js)
const form = document.querySelector("#form-produto");
const aviso = document.querySelector("#aviso");

form.addEventListener("submit", async (e) => {
  e.preventDefault();   // não recarrega a página

  const produto = {
    tipo: document.querySelector("#tipo").value,
    nome: document.querySelector("#nome").value.trim(),
    preco: Number(document.querySelector("#preco").value),
    tamanho: document.querySelector("#tamanho").value,
  };

  if (produto.nome === "") {
    aviso.textContent = "Informe o nome do produto.";
    return;
  }
  if (!(produto.preco > 0)) {
    aviso.textContent = "O preço precisa ser maior que zero.";
    return;
  }

  aviso.textContent = "Enviando...";
  try {
    const resposta = await fetch(`${API}/produtos`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(produto),
    });
    const corpo = await resposta.json();

    if (!resposta.ok) {
      // o 422 do Pydantic manda uma lista de erros; os nossos mandam um texto
      const detalhe = Array.isArray(corpo.detail)
        ? corpo.detail.map((d) => d.msg).join("; ")
        : corpo.detail;
      aviso.textContent = `Não cadastrou: ${detalhe}`;
      return;
    }
    aviso.textContent = `${corpo.nome} cadastrado com o número ${corpo.id}.`;
    form.reset();
  } catch (erro) {
    aviso.textContent = "Não foi possível falar com a API. Ela está ligada?";
    console.error(erro);
  }
});
