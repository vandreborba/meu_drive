import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meu_drive/dados/provedores/atualizacao_provider.dart';
import 'package:meu_drive/dados/servicos/ponte_motor_servico.dart';
import 'package:meu_drive/l10n/gerado/app_localizations.dart';
import 'package:meu_drive/utils_geral/caixa_dialogo.dart';

/// Executa o fluxo de atualização: libera a permissão, baixa e abre o instalador.
Future<void> executarAtualizacao(BuildContext context, WidgetRef ref) async {
  final textos = AppLocalizations.of(context);
  final ponte = PonteMotorServico();
  if (!await ponte.podeInstalarApks()) {
    await ponte.pedirPermissaoInstalar();
    if (context.mounted) {
      MinhaCaixaDialogo.mostrarSnackBar(context, textos.permitirInstalar);
    }
    return;
  }
  final erro = await ref.read(atualizacaoProvider.notifier).baixarEInstalar();
  if (erro != null && context.mounted) {
    MinhaCaixaDialogo.mostrarSnackBar(context, erro, erro: true);
  }
}

/// Cartão que aparece quando há uma versão nova publicada.
class CartaoAtualizacao extends ConsumerWidget {
  const CartaoAtualizacao({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = AppLocalizations.of(context);
    final esquema = Theme.of(context).colorScheme;
    final estado = ref.watch(atualizacaoProvider);
    final disponivel = estado.disponivel;
    if (disponivel == null) return const SizedBox.shrink();

    return Card(
      color: esquema.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(MdiIcons.rocketLaunchOutline, color: esquema.onTertiaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${textos.novaVersao} ${disponivel.versao}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: esquema.onTertiaryContainer),
                  ),
                ),
              ],
            ),
            if (disponivel.notas.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                disponivel.notas.trim(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: esquema.onTertiaryContainer),
              ),
            ],
            const SizedBox(height: 12),
            if (estado.baixando)
              Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 12),
                  Text(textos.baixandoAtualizacao),
                ],
              )
            else
              FilledButton.icon(
                onPressed: () => executarAtualizacao(context, ref),
                icon: const Icon(MdiIcons.downloadOutline),
                label: Text(textos.atualizarApp),
              ),
          ],
        ),
      ),
    );
  }
}
