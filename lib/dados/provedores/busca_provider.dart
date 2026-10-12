import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../modelos/item_arquivo.dart';
import '../servicos/arquivos_locais_servico.dart';

/// Estado da tela de busca de arquivos.
class EstadoBusca {
  final String consulta;
  final List<ItemArquivo> resultados;
  final bool carregando;
  final String? erro;

  const EstadoBusca({
    this.consulta = '',
    this.resultados = const [],
    this.carregando = false,
    this.erro,
  });
}

/// Busca arquivos no armazenamento local, com debounce e resultados parciais.
class BuscaNotifier extends Notifier<EstadoBusca> {
  final ArquivosLocaisServico _servico = ArquivosLocaisServico();

  Timer? _debounce;
  StreamSubscription<ItemArquivo>? _assinatura;

  @override
  EstadoBusca build() {
    ref.onDispose(() {
      _debounce?.cancel();
      _assinatura?.cancel();
    });
    return const EstadoBusca();
  }

  /// Atualiza a consulta e agenda a varredura (debounce de 600 ms).
  void definirConsulta(String consulta) {
    _cancelar();
    final limpa = consulta.trim();
    // Consultas muito curtas varreriam todo o armazenamento sem retorno útil.
    if (limpa.length < 2) {
      state = EstadoBusca(consulta: limpa);
      return;
    }
    state = EstadoBusca(consulta: limpa, carregando: true);
    _debounce = Timer(
      const Duration(milliseconds: 600),
      () => _executar(limpa),
    );
  }

  void _executar(String consulta) {
    final resultados = <ItemArquivo>[];
    _assinatura = _servico
        .buscar(consulta)
        .listen(
          (item) {
            if (state.consulta != consulta) return;
            resultados.add(item);
            state = EstadoBusca(
              consulta: consulta,
              resultados: List.unmodifiable(resultados),
              carregando: true,
            );
          },
          onDone: () {
            if (state.consulta != consulta) return;
            state = EstadoBusca(
              consulta: consulta,
              resultados: List.unmodifiable(resultados),
            );
          },
          onError: (Object erro) {
            if (state.consulta != consulta) return;
            state = EstadoBusca(
              consulta: consulta,
              resultados: List.unmodifiable(resultados),
              erro: erro.toString(),
            );
          },
        );
  }

  /// Limpa a busca e volta ao estado inicial.
  void limpar() {
    _cancelar();
    state = const EstadoBusca();
  }

  void _cancelar() {
    _debounce?.cancel();
    _debounce = null;
    _assinatura?.cancel();
    _assinatura = null;
  }
}

final buscaProvider = NotifierProvider<BuscaNotifier, EstadoBusca>(
  BuscaNotifier.new,
);
