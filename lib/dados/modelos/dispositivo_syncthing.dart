/// Um dispositivo (computador/celular) que sincroniza com o motor.
class DispositivoSyncthing {
  final String id;
  final String nome;

  const DispositivoSyncthing({required this.id, required this.nome});

  factory DispositivoSyncthing.doJson(Map<String, dynamic> json) {
    final id = (json['deviceID'] ?? '').toString();
    final nome = (json['name'] ?? '').toString().trim();
    return DispositivoSyncthing(
      id: id,
      nome: nome.isNotEmpty ? nome : _abreviar(id),
    );
  }

  static String _abreviar(String id) {
    if (id.length <= 7) return id;
    return id.substring(0, 7).toUpperCase();
  }

  /// ID abreviado, como o Syncthing mostra na interface.
  String get idCurto => _abreviar(id);
}
