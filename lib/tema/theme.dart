import 'package:flutter/material.dart';

/// Tema central do Meu Drive.
///
/// As telas devem sempre usar `Theme.of(context).colorScheme` e
/// `Theme.of(context).textTheme` — nunca cores ou estilos fixos.
class MeuDriveTema {
  const MeuDriveTema._();

  /// Verde "sincronizado", usado como semente do Material 3.
  static const Color _semente = Color(0xFF2E7D32);

  static ThemeData claro() => _montar(Brightness.light);

  static ThemeData escuro() => _montar(Brightness.dark);

  static ThemeData _montar(Brightness brilho) {
    final esquema = ColorScheme.fromSeed(seedColor: _semente, brightness: brilho);
    return ThemeData(
      colorScheme: esquema,
      useMaterial3: true,
    );
  }
}
