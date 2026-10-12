import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meu_drive/dados/modelos/item_arquivo.dart';
import 'package:meu_drive/dados/provedores/busca_provider.dart';
import 'package:meu_drive/dados/provedores/motor_provider.dart';
import 'package:meu_drive/l10n/gerado/app_localizations.dart';
import 'package:meu_drive/utils_geral/abrir_item_aux.dart';
import 'package:meu_drive/utils_geral/espaco_aux.dart';
import 'package:meu_drive/widgets/aviso_arquivos.dart';
import 'package:meu_drive/widgets/tile_arquivo.dart';

/// Busca arquivos em todo o armazenamento do aparelho.
class BuscaScreen extends ConsumerStatefulWidget {
  const BuscaScreen({super.key});

  @override
  ConsumerState<BuscaScreen> createState() => _BuscaScreenState();
}

class _BuscaScreenState extends ConsumerState<BuscaScreen> {
  final TextEditingController _controlador = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Evita abrir a busca com resultados antigos de uma sessão anterior.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(buscaProvider.notifier).limpar();
    });
  }

  @override
  void dispose() {
    // Cancela varredura em andamento ao sair da tela.
    ref.read(buscaProvider.notifier).limpar();
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textos = AppLocalizations.of(context);
    final estado = ref.watch(buscaProvider);
    final temPermissao = ref.watch(motorProvider).temPermissaoArquivos;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controlador,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: textos.buscarDica,
            border: InputBorder.none,
          ),
          onChanged: ref.read(buscaProvider.notifier).definirConsulta,
        ),
        actions: [
          if (estado.consulta.isNotEmpty)
            IconButton(
              tooltip: textos.cancelar,
              onPressed: () {
                _controlador.clear();
                ref.read(buscaProvider.notifier).limpar();
              },
              icon: const Icon(MdiIcons.close),
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
    EstadoBusca estado,
  ) {
    if (estado.consulta.length < 2) {
      return AvisoArquivos(
        icone: MdiIcons.fileSearchOutline,
        texto: textos.buscarInstrucao,
      );
    }
    if (estado.carregando && estado.resultados.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (estado.erro != null && estado.resultados.isEmpty) {
      return AvisoArquivos(
        icone: MdiIcons.alertCircleOutline,
        texto: textos.erroTitulo,
      );
    }
    if (estado.resultados.isEmpty) {
      return AvisoArquivos(
        icone: MdiIcons.fileRemoveOutline,
        texto: textos.nenhumResultado,
      );
    }
    final itens = [...estado.resultados]
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${itens.length} ${textos.nResultados}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(
              bottom: 4 + espacoInferiorSistema(context),
            ),
            itemCount: itens.length,
            itemBuilder: (context, indice) =>
                _linha(context, textos, itens, indice),
          ),
        ),
      ],
    );
  }

  Widget _linha(
    BuildContext context,
    AppLocalizations textos,
    List<ItemArquivo> itens,
    int indice,
  ) {
    final item = itens[indice];
    return TileArquivo(
      item: item,
      subtitulo: item.pastaPai,
      onTap: () => abrirArquivo(context, item, itens),
      acao: IconButton(
        tooltip: textos.abrirPasta,
        icon: const Icon(MdiIcons.folderOpenOutline),
        onPressed: () => abrirPastaDe(context, item),
      ),
    );
  }
}
