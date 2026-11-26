// Etapa 22: onde está a API (o único lugar que sabe disso)
// Local (aula): front na porta 5500 e API na 8000.
// Produção (EC2): o nginx serve o front e repassa /api para a API, na mesma origem.
const API = location.port === "5500" ? "http://127.0.0.1:8000" : "/api";

// Cabeçalhos extras em todo pedido. Vazio aqui; no site do S3 (disciplina de Cloud)
// o script de publicação troca este arquivo para mandar o x-api-key do API Gateway.
const API_HEADERS = {};
