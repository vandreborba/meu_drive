/// Um arquivo ou pasta do armazenamento do aparelho.
class ItemArquivo {
  final String nome;
  final String caminho;
  final bool ehDiretorio;
  final int tamanho;
  final DateTime? modificado;

  const ItemArquivo({
    required this.nome,
    required this.caminho,
    required this.ehDiretorio,
    this.tamanho = 0,
    this.modificado,
  });

  /// Pasta que contém este item (caminho sem o último segmento).
  String get pastaPai {
    final separador = caminho.lastIndexOf('/');
    if (separador < 0) return caminho;
    if (separador == 0) return '/';
    return caminho.substring(0, separador);
  }

  /// Último segmento de um caminho absoluto (vazio se não houver segmentos).
  static String nomeDe(String caminho) {
    final partes = caminho.split('/').where((p) => p.isNotEmpty);
    return partes.isEmpty ? '' : partes.last;
  }
}
