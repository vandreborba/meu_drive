import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import 'package:meu_drive/dados/modelos/item_arquivo.dart';
import 'package:meu_drive/dados/servicos/arquivos_locais_servico.dart';
import 'package:meu_drive/l10n/gerado/app_localizations.dart';
import 'package:meu_drive/telas/explorador_screen.dart';
import 'package:meu_drive/telas/visualizador_screen.dart';
import 'package:meu_drive/utils_geral/arquivos_aux.dart';
import 'package:meu_drive/utils_geral/caixa_dialogo.dart';

/// Abre [item] com o app padrão; imagens abrem no visualizador interno.
///
/// [lista] é a lista em exibição, usada para navegar entre imagens próximas.
Future<void> abrirArquivo(
  BuildContext context,
  ItemArquivo item,
  List<ItemArquivo> lista,
) async {
  if (item.ehDiretorio) return;
  if (ehArquivoDeImagem(item.nome)) {
    final imagens = lista
        .where((i) => !i.ehDiretorio && ehArquivoDeImagem(i.nome))
        .map((i) => i.caminho)
        .toList(growable: false);
    final indice = imagens.indexOf(item.caminho);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VisualizadorScreen(
          caminhos: imagens.isEmpty ? [item.caminho] : imagens,
          indiceInicial: indice < 0 ? 0 : indice,
        ),
      ),
    );
    return;
  }
  final resultado = await OpenFilex.open(item.caminho);
  if (resultado.type != ResultType.done && context.mounted) {
    MinhaCaixaDialogo.mostrarSnackBar(
      context,
      AppLocalizations.of(context).arquivoNaoAbrir,
      erro: true,
    );
  }
}

/// Abre no explorador a pasta que contém [item].
void abrirPastaDe(BuildContext context, ItemArquivo item) {
  final pasta = item.pastaPai;
  if (pasta == item.caminho) return;
  final nome = ItemArquivo.nomeDe(pasta);
  // A raiz do armazenamento não tem um nome amigável ("0").
  final titulo = nome.isEmpty || pasta == ArquivosLocaisServico.raizPadrao
      ? AppLocalizations.of(context).explorarCelular
      : nome;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ExploradorScreen(caminhoInicial: pasta, titulo: titulo),
    ),
  );
}
