import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:meu_drive/dados/modelos/estado_pasta.dart';
import 'package:meu_drive/l10n/gerado/app_localizations.dart';

/// Selo compacto que resume o estado de sincronização de uma pasta.
class SeloEstadoPasta extends StatelessWidget {
  final EstadoPasta? estado;

  const SeloEstadoPasta({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final textos = AppLocalizations.of(context);
    final esquema = Theme.of(context).colorScheme;
    final fase = estado?.fase ?? FasePasta.desconhecida;

    final (String texto, IconData icone, Color cor) = switch (fase) {
      FasePasta.sincronizado => (textos.sincronizado, MdiIcons.checkCircleOutline, esquema.primary),
      FasePasta.sincronizando => (
        _textoSincronizando(textos),
        MdiIcons.sync,
        esquema.tertiary,
      ),
      FasePasta.pausada => (textos.pausada, MdiIcons.pauseCircleOutline, esquema.outline),
      FasePasta.parada => (textos.pausada, MdiIcons.pauseCircleOutline, esquema.outline),
      FasePasta.erro => (textos.erroPasta, MdiIcons.alertCircleOutline, esquema.error),
      FasePasta.desconhecida => (
        textos.estadoDesconhecido,
        MdiIcons.helpCircleOutline,
        esquema.outline,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 16, color: cor),
          const SizedBox(width: 6),
          Text(texto, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cor)),
        ],
      ),
    );
  }

  String _textoSincronizando(AppLocalizations textos) {
    final percentual = estado?.percentual ?? 0;
    if (percentual > 0 && percentual < 100) {
      return '${textos.sincronizando} $percentual%';
    }
    return textos.sincronizando;
  }
}
