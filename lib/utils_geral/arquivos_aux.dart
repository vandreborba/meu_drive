/// Utilitários de reconhecimento de tipo de arquivo.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

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

/// Ícone representativo do arquivo, de acordo com a extensão.
IconData iconeParaArquivo(String nome) {
  final minusculo = nome.toLowerCase();
  if (ehArquivoDeImagem(minusculo)) return MdiIcons.imageOutline;
  if (minusculo.endsWith('.mp4') ||
      minusculo.endsWith('.mkv') ||
      minusculo.endsWith('.mov') ||
      minusculo.endsWith('.avi')) {
    return MdiIcons.videoOutline;
  }
  if (minusculo.endsWith('.mp3') ||
      minusculo.endsWith('.ogg') ||
      minusculo.endsWith('.wav') ||
      minusculo.endsWith('.m4a')) {
    return MdiIcons.musicNoteOutline;
  }
  if (minusculo.endsWith('.pdf')) return MdiIcons.filePdfBox;
  if (minusculo.endsWith('.zip') ||
      minusculo.endsWith('.rar') ||
      minusculo.endsWith('.7z')) {
    return MdiIcons.zipBoxOutline;
  }
  return MdiIcons.fileOutline;
}
