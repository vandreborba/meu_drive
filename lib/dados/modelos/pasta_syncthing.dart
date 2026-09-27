/// Uma pasta de sincronização declarada no motor (Syncthing-Fork).
///
/// O `rotulo` (label) é o nome amigável que o usuário vê; se estiver vazio,
/// usamos o último segmento do caminho. O `id` técnico fica escondido da UI.
class PastaSyncthing {
  final String id;
  final String rotulo;
  final String caminho;
  final String tipo;
  final bool pausada;

  /// IDs dos dispositivos com quem esta pasta é compartilhada.
  final List<String> dispositivos;

  /// Intervalo de verificação periódica, em segundos (0 = desativado).
  final int rescanIntervaloS;

  /// Se o motor observa as mudanças no sistema de arquivos em tempo real.
  final bool fsWatcherEnabled;

  const PastaSyncthing({
    required this.id,
    required this.rotulo,
    required this.caminho,
    required this.tipo,
    required this.pausada,
    this.dispositivos = const [],
    this.rescanIntervaloS = 3600,
    this.fsWatcherEnabled = true,
  });

  factory PastaSyncthing.doJson(Map<String, dynamic> json) {
    final brutoDispositivos = (json['devices'] as List?) ?? const [];
    final dispositivos = brutoDispositivos
        .whereType<Map<String, dynamic>>()
        .map((item) => (item['deviceID'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    return PastaSyncthing(
      id: (json['id'] ?? '').toString(),
      rotulo: (json['label'] ?? '').toString(),
      caminho: expandirCaminhoSyncthing((json['path'] ?? '').toString()),
      tipo: (json['type'] ?? 'sendreceive').toString(),
      pausada: json['paused'] == true,
      dispositivos: dispositivos,
      rescanIntervaloS: _paraInt(json['rescanIntervalS'], 3600),
      fsWatcherEnabled: json['fsWatcherEnabled'] != false,
    );
  }

  static int _paraInt(Object? valor, int padrao) {
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    return int.tryParse(valor?.toString() ?? '') ?? padrao;
  }

  /// O motor pode guardar caminhos com `~/`; no Android isso equivale ao
  /// armazenamento compartilhado principal.
  static String expandirCaminhoSyncthing(String caminho) {
    if (caminho.startsWith('~/')) {
      return '/storage/emulated/0/${caminho.substring(2)}';
    }
    if (caminho == '~') {
      return '/storage/emulated/0';
    }
    return caminho;
  }

  String get nomeAmigavel {
    if (rotulo.trim().isNotEmpty) return rotulo.trim();
    final partes = caminho.split('/').where((parte) => parte.trim().isNotEmpty).toList();
    return partes.isNotEmpty ? partes.last : id;
  }

  @override
  bool operator ==(Object other) =>
      other is PastaSyncthing && other.id == id && other.caminho == caminho;

  @override
  int get hashCode => Object.hash(id, caminho);
}
