import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../servicos/armazenamento_servico.dart';

/// Tema escolhido pelo usuário (sistema, claro ou escuro), persistido.
class TemaNotifier extends Notifier<ThemeMode> {
  final ArmazenamentoServico _armazenamento = ArmazenamentoServico();

  @override
  ThemeMode build() {
    _carregar();
    return ThemeMode.system;
  }

  Future<void> _carregar() async {
    state = await _armazenamento.lerTema();
  }

  Future<void> definir(ThemeMode modo) async {
    state = modo;
    await _armazenamento.salvarTema(modo);
  }
}

final temaProvider = NotifierProvider<TemaNotifier, ThemeMode>(TemaNotifier.new);
