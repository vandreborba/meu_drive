import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'syncthing_rest_servico.dart';

/// Preferências locais do Meu Drive (não do motor).
class ArmazenamentoServico {
  static const String _chaveSetupConcluido = 'setup_concluido';
  static const String _chavePortaGui = 'porta_gui';
  static const String _chaveTema = 'tema';
  static const String _chaveExploradorPorPasta = 'explorador_por_pasta';
  static const String _chaveCacheMotor = 'cache_motor';
  static const String _chaveUltimaSincronizacao = 'ultima_sincronizacao';

  /// Pastas/dispositivos conhecidos do motor, para abrir o app sem esperar a
  /// conexão (sincroniza em segundo plano).
  Future<String?> lerCacheMotorJson() async =>
      (await SharedPreferences.getInstance()).getString(_chaveCacheMotor);

  Future<void> salvarCacheMotorJson(String json) async =>
      (await SharedPreferences.getInstance()).setString(_chaveCacheMotor, json);

  /// Horário do último sync realmente verificado com os computadores.
  Future<DateTime?> lerUltimaSincronizacao() async {
    final ms = (await SharedPreferences.getInstance()).getInt(_chaveUltimaSincronizacao);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> salvarUltimaSincronizacao(DateTime quando) async =>
      (await SharedPreferences.getInstance())
          .setInt(_chaveUltimaSincronizacao, quando.millisecondsSinceEpoch);

  /// Preferências do explorador por diretório, como JSON.
  Future<String?> lerExploradorJson() async =>
      (await SharedPreferences.getInstance()).getString(_chaveExploradorPorPasta);

  Future<void> salvarExploradorJson(String json) async =>
      (await SharedPreferences.getInstance()).setString(_chaveExploradorPorPasta, json);

  Future<ThemeMode> lerTema() async {
    final prefs = await SharedPreferences.getInstance();
    return switch (prefs.getString(_chaveTema)) {
      'claro' => ThemeMode.light,
      'escuro' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> salvarTema(ThemeMode modo) async {
    final prefs = await SharedPreferences.getInstance();
    final valor = switch (modo) {
      ThemeMode.light => 'claro',
      ThemeMode.dark => 'escuro',
      ThemeMode.system => 'sistema',
    };
    await prefs.setString(_chaveTema, valor);
  }

  Future<bool> setupConcluido() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_chaveSetupConcluido) ?? false;
  }

  Future<void> marcarSetupConcluido() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chaveSetupConcluido, true);
  }

  Future<int> lerPortaGui() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_chavePortaGui) ?? SyncthingRestServico.portaPadrao;
  }

  Future<void> salvarPortaGui(int porta) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_chavePortaGui, porta);
  }
}
