import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Espaço do armazenamento do aparelho.
class EspacoArmazenamento {
  final int totalBytes;
  final int livreBytes;

  const EspacoArmazenamento({required this.totalBytes, required this.livreBytes});

  int get usadoBytes => totalBytes - livreBytes;
}

/// Configuração lida do `config.xml` do motor.
class ConfigMotor {
  /// Endereço do GUI no formato `host:porta` (ex.: `127.0.0.1:41231`).
  final String? endereco;
  final bool tls;
  final String? apiKey;

  const ConfigMotor({this.endereco, this.tls = false, this.apiKey});

  String? get host => _partes?.first;

  int? get porta => int.tryParse(_partes?.last ?? '');

  List<String>? get _partes {
    final valor = endereco;
    if (valor == null || valor.isEmpty) return null;
    final separador = valor.lastIndexOf(':');
    if (separador <= 0 || separador == valor.length - 1) return null;
    return [valor.substring(0, separador), valor.substring(separador + 1)];
  }
}

/// Ponte para as operações nativas do Android (ver `MainActivity.kt`).
///
/// O motor (Syncthing) é embutido no app e executado por um serviço em primeiro
/// plano. Aqui controlamos esse serviço e a permissão "Todos os arquivos".
class PonteMotorServico {
  static const MethodChannel _canal = MethodChannel('meu_drive/motor');

  /// Inicia o serviço que executa o motor embutido.
  Future<void> iniciarMotor() async {
    await _canal.invokeMethod<bool>('iniciarMotor');
    debugPrint('[Ponte] iniciarMotor');
  }

  Future<void> pararMotor() async {
    await _canal.invokeMethod<bool>('pararMotor');
    debugPrint('[Ponte] pararMotor');
  }

  Future<bool> motorRodando() async {
    final resultado = await _canal.invokeMethod<bool>('motorRodando');
    debugPrint('[Ponte] motorRodando -> ${resultado ?? false}');
    return resultado ?? false;
  }

  /// Importa a configuração exportada pelo Syncthing-Fork (mesmo device ID).
  /// Com [forcar], substitui a configuração atual. Retorna `true` se importou.
  Future<bool> importarConfigMotor({bool forcar = false}) async {
    final resultado = await _canal.invokeMethod<bool>('importarConfigMotor', {'forcar': forcar});
    debugPrint('[Ponte] importarConfigMotor(forcar=$forcar) -> ${resultado ?? false}');
    return resultado ?? false;
  }

  /// Exporta a configuração do motor (config.xml + chaves) para
  /// `backups/syncthing/config.zip`. Retorna o caminho ou `null`.
  Future<String?> exportarConfigMotor() async {
    final caminho = await _canal.invokeMethod<String>('exportarConfigMotor');
    debugPrint('[Ponte] exportarConfigMotor -> $caminho');
    return caminho;
  }

  /// Lê endereço/TLS/API key do `config.xml` do motor.
  Future<ConfigMotor?> lerConfigMotor() async {
    final mapa = await _canal.invokeMethod<Map<dynamic, dynamic>>('lerConfigMotor');
    if (mapa == null) return null;
    final config = ConfigMotor(
      endereco: mapa['endereco'] as String?,
      tls: mapa['tls'] as bool? ?? false,
      apiKey: mapa['apiKey'] as String?,
    );
    debugPrint('[Ponte] lerConfigMotor -> ${config.endereco} tls=${config.tls} '
        'apiKey=${config.apiKey == null ? 'null' : 'ok'}');
    return config;
  }

  /// Últimas linhas do log do motor (para diagnóstico).
  Future<String> lerLogMotor() async {
    final log = await _canal.invokeMethod<String>('lerLogMotor');
    return log ?? '';
  }

  /// Lê a API key do `config.xml` do motor (acesso ao REST sem CSRF).
  Future<String?> lerApiKeyMotor() async {
    final chave = await _canal.invokeMethod<String>('lerApiKeyMotor');
    debugPrint('[Ponte] lerApiKeyMotor -> ${chave == null ? 'null' : 'ok'}');
    return chave;
  }

  Future<bool> temTodosArquivos() async {
    final resultado = await _canal.invokeMethod<bool>('temTodosArquivos');
    debugPrint('[Ponte] temTodosArquivos -> ${resultado ?? false}');
    return resultado ?? false;
  }

  Future<void> pedirTodosArquivos() async {
    await _canal.invokeMethod<bool>('pedirTodosArquivos');
    debugPrint('[Ponte] pedirTodosArquivos chamado');
  }

  Future<void> pedirNotificacoes() async {
    await _canal.invokeMethod<bool>('pedirNotificacoes');
    debugPrint('[Ponte] pedirNotificacoes chamado');
  }

  /// Espaço do armazenamento do aparelho (em bytes).
  Future<EspacoArmazenamento?> espacoArmazenamento() async {
    final mapa = await _canal.invokeMethod<Map<dynamic, dynamic>>('espacoArmazenamento');
    if (mapa == null || mapa.isEmpty) return null;
    final total = (mapa['total'] as num?)?.toInt() ?? 0;
    final livre = (mapa['livre'] as num?)?.toInt() ?? 0;
    if (total <= 0) return null;
    return EspacoArmazenamento(totalBytes: total, livreBytes: livre);
  }

  /// Se o app pode instalar APKs (origens desconhecidas).
  Future<bool> podeInstalarApks() async {
    final resultado = await _canal.invokeMethod<bool>('podeInstalarApks');
    return resultado ?? false;
  }

  /// Abre a tela para liberar "instalar apps desconhecidos" para este app.
  Future<void> pedirPermissaoInstalar() async {
    await _canal.invokeMethod<bool>('pedirPermissaoInstalar');
  }

  /// Pasta de destino dos arquivos recebidos via "Compartilhar" (ou `null`).
  Future<String?> lerPastaCompartilhamento() async {
    final caminho = await _canal.invokeMethod<String>('lerPastaCompartilhamento');
    debugPrint('[Ponte] lerPastaCompartilhamento -> $caminho');
    return caminho;
  }

  /// Define a pasta de destino dos arquivos recebidos (`null` para remover).
  Future<void> definirPastaCompartilhamento(String? caminho) async {
    await _canal.invokeMethod<bool>(
      'definirPastaCompartilhamento',
      {'caminho': caminho},
    );
    debugPrint('[Ponte] definirPastaCompartilhamento -> $caminho');
  }
}
