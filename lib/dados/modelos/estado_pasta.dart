import 'pasta_syncthing.dart';

/// Fase visual de uma pasta, derivada do estado bruto do motor.
enum FasePasta { sincronizado, sincronizando, parada, pausada, erro, desconhecida }

/// Estado de sincronização de uma pasta, pronto para a interface.
class EstadoPasta {
  final FasePasta fase;
  final int percentual;
  final int precisaBytes;
  final int itens;
  final int bytes;
  final String? detalhe;

  const EstadoPasta({
    required this.fase,
    this.percentual = 0,
    this.precisaBytes = 0,
    this.itens = 0,
    this.bytes = 0,
    this.detalhe,
  });

  static const EstadoPasta desconhecido = EstadoPasta(fase: FasePasta.desconhecida);

  factory EstadoPasta.doStatus(PastaSyncthing pasta, Map<String, dynamic> status) {
    if (pasta.pausada) {
      return const EstadoPasta(fase: FasePasta.pausada);
    }

    final bruto = (status['state'] ?? '').toString();
    final precisaBytes = _paraInt(status['needBytes']);
    final globalBytes = _paraInt(status['globalBytes']);
    final emSyncBytes = _paraInt(status['inSyncBytes']);
    final itens = _paraInt(status['localTotalItems']);
    final bytes = _paraInt(status['localBytes']);
    final percentual = globalBytes > 0 ? ((emSyncBytes * 100) ~/ globalBytes).clamp(0, 100) : 100;

    switch (bruto) {
      case 'error':
      case 'failed':
        return EstadoPasta(
          fase: FasePasta.erro,
          precisaBytes: precisaBytes,
          itens: itens,
          bytes: bytes,
          detalhe: (status['error'] ?? '').toString(),
        );
      case 'syncing':
      case 'scanning':
      case 'scanning-wait':
      case 'sync-preparing':
      case 'cleaning':
        return EstadoPasta(
          fase: FasePasta.sincronizando,
          percentual: percentual,
          precisaBytes: precisaBytes,
          itens: itens,
          bytes: bytes,
        );
      case 'idle':
        return EstadoPasta(
          fase: FasePasta.sincronizado,
          percentual: 100,
          precisaBytes: precisaBytes,
          itens: itens,
          bytes: bytes,
        );
      case '':
        return desconhecido;
      default:
        return EstadoPasta(fase: FasePasta.desconhecida, detalhe: bruto);
    }
  }

  static int _paraInt(Object? valor) {
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    return int.tryParse(valor?.toString() ?? '') ?? 0;
  }
}
