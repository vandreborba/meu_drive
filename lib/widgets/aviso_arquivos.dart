import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:meu_drive/l10n/gerado/app_localizations.dart';

/// Aviso central simples (ícone + texto) para listas vazias ou instruções.
class AvisoArquivos extends StatelessWidget {
  final IconData icone;
  final String texto;

  const AvisoArquivos({super.key, required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 48, color: esquema.outline),
            const SizedBox(height: 12),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Mensagem de permissão de arquivos pendente, com botão para conceder.
class SemPermissaoArquivos extends StatelessWidget {
  final Future<void> Function() onConceder;

  const SemPermissaoArquivos({super.key, required this.onConceder});

  @override
  Widget build(BuildContext context) {
    final textos = AppLocalizations.of(context);
    final esquema = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          color: esquema.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  MdiIcons.shieldAlertOutline,
                  size: 48,
                  color: esquema.onSecondaryContainer,
                ),
                const SizedBox(height: 12),
                Text(
                  textos.permissaoTitulo,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: esquema.onSecondaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  textos.permissaoTexto,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: esquema.onSecondaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onConceder,
                  child: Text(textos.concederPermissao),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
