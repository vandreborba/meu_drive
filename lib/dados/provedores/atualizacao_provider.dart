import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import '../servicos/atualizacao_servico.dart';

/// Estado da verificação/instalação de atualizações.
class EstadoAtualizacao {
  final bool verificando;
  final bool baixando;
  final VersaoDisponivel? disponivel;
  final String? erro;

  const EstadoAtualizacao({
    this.verificando = false,
    this.baixando = false,
    this.disponivel,
    this.erro,
  });

  EstadoAtualizacao copyWith({
    bool? verificando,
    bool? baixando,
    VersaoDisponivel? disponivel,
    String? erro,
    bool limparDisponivel = false,
    bool limparErro = false,
  }) {
    return EstadoAtualizacao(
      verificando: verificando ?? this.verificando,
      baixando: baixando ?? this.baixando,
      disponivel: limparDisponivel ? null : (disponivel ?? this.disponivel),
      erro: limparErro ? null : (erro ?? this.erro),
    );
  }
}

class AtualizacaoNotifier extends Notifier<EstadoAtualizacao> {
  final AtualizacaoServico _servico = AtualizacaoServico();

  @override
  EstadoAtualizacao build() => const EstadoAtualizacao();

  Future<void> verificar() async {
    state = state.copyWith(verificando: true, limparErro: true);
    try {
      final disponivel = await _servico.verificar();
      state = state.copyWith(verificando: false, disponivel: disponivel, limparDisponivel: disponivel == null);
    } catch (e) {
      state = state.copyWith(verificando: false, erro: e.toString());
    }
  }

  Future<String> versaoAtual() => _servico.versaoAtual();

  /// Baixa o APK e abre o instalador. Devolve a mensagem de erro, ou null se ok.
  Future<String?> baixarEInstalar() async {
    final versao = state.disponivel;
    if (versao == null) return null;
    state = state.copyWith(baixando: true, limparErro: true);
    try {
      final caminho = await _servico.baixar(versao.urlApk);
      final resultado = await _servico.instalar(caminho);
      state = state.copyWith(baixando: false);
      return resultado.type == ResultType.done ? null : resultado.message;
    } catch (e) {
      state = state.copyWith(baixando: false, erro: e.toString());
      return e.toString();
    }
  }
}

final atualizacaoProvider =
    NotifierProvider<AtualizacaoNotifier, EstadoAtualizacao>(AtualizacaoNotifier.new);
