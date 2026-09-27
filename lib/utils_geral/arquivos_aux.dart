/// Utilitários de reconhecimento de tipo de arquivo.
library;

const List<String> _extensoesImagem = [
  '.jpg',
  '.jpeg',
  '.png',
  '.gif',
  '.webp',
  '.bmp',
  '.heic',
  '.heif',
];

/// Se o arquivo é uma imagem (para mostrar miniatura / visualizador).
bool ehArquivoDeImagem(String caminhoOuNome) {
  final minusculo = caminhoOuNome.toLowerCase();
  return _extensoesImagem.any(minusculo.endsWith);
}
