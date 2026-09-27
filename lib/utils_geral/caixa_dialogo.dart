import 'package:flutter/material.dart';

import 'package:meu_drive/l10n/gerado/app_localizations.dart';

/// Uma opção apresentada por [MinhaCaixaDialogo.escolher].
class OpcaoDialogo {
  final String texto;
  final IconData icone;
  final bool primario;

  const OpcaoDialogo({required this.texto, required this.icone, this.primario = false});
}

/// Ponto único para SnackBars e diálogos do app.
///
/// Nunca use `showDialog` ou `ScaffoldMessenger` diretamente nas telas.
class MinhaCaixaDialogo {
  const MinhaCaixaDialogo._();

  static void mostrarSnackBar(BuildContext context, String texto, {bool erro = false}) {
    final esquema = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: erro ? esquema.errorContainer : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Future<bool> confirmar(
    BuildContext context, {
    required String titulo,
    required String mensagem,
    String? textoConfirmar,
  }) async {
    final textos = AppLocalizations.of(context);
    final resultado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: Text(textos.cancelar),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            child: Text(textoConfirmar ?? textos.salvar),
          ),
        ],
      ),
    );
    return resultado ?? false;
  }

  /// Apresenta uma lista de opções e devolve o índice da escolhida (ou null).
  static Future<int?> escolher(
    BuildContext context, {
    required String titulo,
    String? mensagem,
    required List<OpcaoDialogo> opcoes,
  }) {
    final textos = AppLocalizations.of(context);
    return showDialog<int>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text(titulo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (mensagem != null) ...[
              Text(mensagem),
              const SizedBox(height: 16),
            ],
            for (var i = 0; i < opcoes.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: opcoes[i].primario
                    ? FilledButton.icon(
                        onPressed: () => Navigator.of(contexto).pop(i),
                        icon: Icon(opcoes[i].icone),
                        label: Text(opcoes[i].texto),
                      )
                    : OutlinedButton.icon(
                        onPressed: () => Navigator.of(contexto).pop(i),
                        icon: Icon(opcoes[i].icone),
                        label: Text(opcoes[i].texto),
                      ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(),
            child: Text(textos.cancelar),
          ),
        ],
      ),
    );
  }

  /// Mostra um diálogo customizado (mantendo o ponto único de diálogos do app).
  static Future<T?> personalizado<T>(
    BuildContext context,
    Widget Function(BuildContext contexto) construtor,
  ) {
    return showDialog<T>(context: context, builder: construtor);
  }

  static Future<String?> pedirTexto(
    BuildContext context, {
    required String titulo,
    String? valorInicial,
    String? dica,
    TextInputType? tipoTeclado,
  }) {
    final textos = AppLocalizations.of(context);
    final controlador = TextEditingController(text: valorInicial);
    return showDialog<String>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: controlador,
          autofocus: true,
          keyboardType: tipoTeclado,
          decoration: InputDecoration(hintText: dica),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(),
            child: Text(textos.cancelar),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contexto).pop(controlador.text),
            child: Text(textos.salvar),
          ),
        ],
      ),
    );
  }

  static Future<void> informar(
    BuildContext context, {
    required String titulo,
    required String mensagem,
  }) {
    final textos = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(contexto).pop(),
            child: Text(textos.ok),
          ),
        ],
      ),
    );
  }
}
