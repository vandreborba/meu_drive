import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'syncthing_rest_servico.dart';

/// Preferências locais do Meu Drive (não do motor).
class ArmazenamentoServico {
  static const String _chaveSetupConcluido = 'setup_concluido';
  static const String _chavePortaGui = 'porta_gui';
  static const String _chaveTema = 'tema';

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
