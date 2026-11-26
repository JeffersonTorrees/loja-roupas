// Etapa 21: o formulário valida antes de enviar (Aula 12)
const form = document.querySelector("#form-produto");
const aviso = document.querySelector("#aviso");

form.addEventListener("submit", (e) => {
  e.preventDefault();   // não recarrega a página

  const nome = document.querySelector("#nome").value.trim();
  const preco = Number(document.querySelector("#preco").value);

  if (nome === "") {
    aviso.textContent = "Informe o nome do produto.";
    return;
  }
  if (!(preco > 0)) {
    aviso.textContent = "O preço precisa ser maior que zero.";
    return;
  }

  aviso.textContent = "Produto cadastrado.";
  form.reset();
});
