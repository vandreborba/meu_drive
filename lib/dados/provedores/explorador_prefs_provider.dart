import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../servicos/armazenamento_servico.dart';

/// Como os itens são exibidos no explorador.
enum ModoVisualizacao { lista, grade }

/// Critério de ordenação dos itens.
enum OrdenacaoArquivo { nome, data, tamanho }

/// Preferências do explorador para um diretório.
class ExploradorPrefs {
  final ModoVisualizacao modo;
  final OrdenacaoArquivo ordenacao;
  final bool ascendente;

  /// 0 = pequenas, 1 = médias, 2 = grandes.
  final int tamanhoMiniatura;

  const ExploradorPrefs({
    this.modo = ModoVisualizacao.lista,
    this.ordenacao = OrdenacaoArquivo.nome,
    this.ascendente = true,
    this.tamanhoMiniatura = 1,
  });

  ExploradorPrefs copyWith({
    ModoVisualizacao? modo,
    OrdenacaoArquivo? ordenacao,
    bool? ascendente,
    int? tamanhoMiniatura,
  }) {
    return ExploradorPrefs(
      modo: modo ?? this.modo,
      ordenacao: ordenacao ?? this.ordenacao,
      ascendente: ascendente ?? this.ascendente,
      tamanhoMiniatura: tamanhoMiniatura ?? this.tamanhoMiniatura,
    );
  }
}

/// Mantém as preferências do explorador **por diretório** (persistidas).
class ExploradorPrefsNotifier extends Notifier<Map<String, ExploradorPrefs>> {
  final ArmazenamentoServico _armazenamento = ArmazenamentoServico();

  @override
  Map<String, ExploradorPrefs> build() {
    _carregar();
    return const {};
  }

  Future<void> _carregar() async {
    final json = await _armazenamento.lerExploradorJson();
    if (json == null || json.isEmpty) return;
    try {
      final mapa = jsonDecode(json) as Map<String, dynamic>;
      state = {
        for (final entrada in mapa.entries)
          entrada.key: _doJson(entrada.value as Map<String, dynamic>),
      };
    } catch (_) {
      // Formato antigo/inválido: ignora e usa os padrões.
    }
  }

  /// Preferências do diretório (padrões se ainda não configurado).
  ExploradorPrefs prefsPara(String caminho) => state[caminho] ?? const ExploradorPrefs();

  Future<void> _definir(String caminho, ExploradorPrefs prefs) async {
    state = {...state, caminho: prefs};
    await _armazenamento.salvarExploradorJson(
      jsonEncode({for (final entrada in state.entries) entrada.key: _paraJson(entrada.value)}),
    );
  }

  Future<void> definirModo(String caminho, ModoVisualizacao modo) =>
      _definir(caminho, prefsPara(caminho).copyWith(modo: modo));

  Future<void> definirOrdenacao(String caminho, OrdenacaoArquivo ordenacao) =>
      _definir(caminho, prefsPara(caminho).copyWith(ordenacao: ordenacao));

  Future<void> definirAscendente(String caminho, bool ascendente) =>
      _definir(caminho, prefsPara(caminho).copyWith(ascendente: ascendente));

  Future<void> definirTamanhoMiniatura(String caminho, int tamanho) =>
      _definir(caminho, prefsPara(caminho).copyWith(tamanhoMiniatura: tamanho.clamp(0, 2)));

  Map<String, dynamic> _paraJson(ExploradorPrefs prefs) => {
        'modo': prefs.modo == ModoVisualizacao.grade ? 'grade' : 'lista',
        'ordenacao': switch (prefs.ordenacao) {
          OrdenacaoArquivo.data => 'data',
          OrdenacaoArquivo.tamanho => 'tamanho',
          OrdenacaoArquivo.nome => 'nome',
        },
        'ascendente': prefs.ascendente,
        'miniatura': prefs.tamanhoMiniatura,
      };

  ExploradorPrefs _doJson(Map<String, dynamic> json) => ExploradorPrefs(
        modo: json['modo'] == 'grade' ? ModoVisualizacao.grade : ModoVisualizacao.lista,
        ordenacao: switch (json['ordenacao']) {
          'data' => OrdenacaoArquivo.data,
          'tamanho' => OrdenacaoArquivo.tamanho,
          _ => OrdenacaoArquivo.nome,
        },
        ascendente: json['ascendente'] as bool? ?? true,
        tamanhoMiniatura: (json['miniatura'] as num?)?.toInt() ?? 1,
      );
}

final exploradorPrefsProvider =
    NotifierProvider<ExploradorPrefsNotifier, Map<String, ExploradorPrefs>>(
  ExploradorPrefsNotifier.new,
);
