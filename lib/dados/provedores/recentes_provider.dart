import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../modelos/item_arquivo.dart';
import '../servicos/arquivos_locais_servico.dart';

/// Estado da tela de últimos arquivos.
class EstadoRecentes {
  final List<ItemArquivo> itens;
  final bool carregando;
  final String? erro;

  const EstadoRecentes({
    this.itens = const [],
    this.carregando = false,
    this.erro,
  });
}

/// Carrega os arquivos modificados mais recentemente no armazenamento local.
class RecentesNotifier extends Notifier<EstadoRecentes> {
  final ArquivosLocaisServico _servico = ArquivosLocaisServico();

  @override
  EstadoRecentes build() => const EstadoRecentes();

  Future<void> carregar() async {
    if (state.carregando) return;
    state = EstadoRecentes(itens: state.itens, carregando: true);
    try {
      final itens = await _servico.recentes();
      state = EstadoRecentes(itens: itens);
    } catch (e) {
      state = EstadoRecentes(erro: e.toString());
    }
  }
}

final recentesProvider = NotifierProvider<RecentesNotifier, EstadoRecentes>(
  RecentesNotifier.new,
);
