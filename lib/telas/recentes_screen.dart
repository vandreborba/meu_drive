import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meu_drive/dados/provedores/motor_provider.dart';
import 'package:meu_drive/dados/provedores/recentes_provider.dart';
import 'package:meu_drive/l10n/gerado/app_localizations.dart';
import 'package:meu_drive/utils_geral/abrir_item_aux.dart';
import 'package:meu_drive/utils_geral/espaco_aux.dart';
import 'package:meu_drive/utils_geral/formatadores_aux.dart';
import 'package:meu_drive/widgets/aviso_arquivos.dart';
import 'package:meu_drive/widgets/tile_arquivo.dart';

/// Lista os arquivos modificados mais recentemente no aparelho.
class RecentesScreen extends ConsumerStatefulWidget {
  const RecentesScreen({super.key});

  @override
  ConsumerState<RecentesScreen> createState() => _RecentesScreenState();
}

class _RecentesScreenState extends ConsumerState<RecentesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(motorProvider).temPermissaoArquivos) {
        ref.read(recentesProvider.notifier).carregar();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textos = AppLocalizations.of(context);
    final estado = ref.watch(recentesProvider);
    final temPermissao = ref.watch(motorProvider).temPermissaoArquivos;

    // Sem permissão a varredura volta vazia; recarrega quando o acesso é
    // concedido dentro desta tela.
    ref.listen(motorProvider.select((e) => e.temPermissaoArquivos), (_, atual) {
      if (atual) ref.read(recentesProvider.notifier).carregar();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(textos.ultimosArquivos),
        actions: [
          IconButton(
            tooltip: textos.atualizar,
            onPressed: () => ref.read(recentesProvider.notifier).carregar(),
            icon: const Icon(MdiIcons.refresh),
          ),
        ],
      ),
      body: !temPermissao
          ? SemPermissaoArquivos(
              onConceder: ref
                  .read(motorProvider.notifier)
                  .concederPermissaoArquivos,
            )
          : _corpo(context, textos, estado),
    );
  }

  Widget _corpo(
    BuildContext context,
    AppLocalizations textos,
    EstadoRecentes estado,
  ) {
    if (estado.carregando && estado.itens.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (estado.erro != null && estado.itens.isEmpty) {
      return AvisoArquivos(
        icone: MdiIcons.alertCircleOutline,
        texto: textos.erroTitulo,
      );
    }
    if (estado.itens.isEmpty) {
      return AvisoArquivos(
        icone: MdiIcons.clockOutline,
        texto: textos.nenhumRecente,
      );
    }
    final itens = estado.itens;
    return ListView.builder(
      padding: EdgeInsets.only(bottom: 4 + espacoInferiorSistema(context)),
      itemCount: itens.length,
      itemBuilder: (context, indice) {
        final item = itens[indice];
        return TileArquivo(
          item: item,
          subtitulo: item.modificado == null
              ? item.pastaPai
              : '${formatarBytes(item.tamanho)} · ${formatarDataHora(item.modificado!)}',
          onTap: () => abrirArquivo(context, item, itens),
        );
      },
    );
  }
}
