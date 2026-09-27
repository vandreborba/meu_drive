import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:meu_drive/dados/modelos/estado_pasta.dart';
import 'package:meu_drive/l10n/gerado/app_localizations.dart';

/// Ícone discreto de estado da pasta (em vez do selo grande).
class IconeEstadoPasta extends StatelessWidget {
  final EstadoPasta? estado;
  final double tamanho;

  const IconeEstadoPasta({super.key, required this.estado, this.tamanho = 22});

  @override
  Widget build(BuildContext context) {
    final textos = AppLocalizations.of(context);
    final esquema = Theme.of(context).colorScheme;
    final fase = estado?.fase ?? FasePasta.desconhecida;

    if (fase == FasePasta.sincronizando) {
      final percentual = estado?.percentual ?? 0;
      final valor = percentual > 0 && percentual < 100 ? percentual / 100 : null;
      return Tooltip(
        message: textos.sincronizando,
        child: SizedBox(
          width: tamanho,
          height: tamanho,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            value: valor,
            color: esquema.tertiary,
          ),
        ),
      );
    }

    final (IconData icone, Color cor, String rotulo) = switch (fase) {
      FasePasta.sincronizado => (MdiIcons.cloudCheckOutline, esquema.primary, textos.sincronizado),
      FasePasta.pausada => (MdiIcons.cloudOffOutline, esquema.outline, textos.pausada),
      FasePasta.parada => (MdiIcons.cloudOffOutline, esquema.outline, textos.pausada),
      FasePasta.erro => (MdiIcons.cloudAlertOutline, esquema.error, textos.erroPasta),
      FasePasta.desconhecida => (
          MdiIcons.cloudQuestionOutline,
          esquema.outline,
          textos.estadoDesconhecido,
        ),
      FasePasta.sincronizando => (MdiIcons.cloudSyncOutline, esquema.tertiary, textos.sincronizando),
    };

    return Tooltip(message: rotulo, child: Icon(icone, color: cor, size: tamanho));
  }
}
