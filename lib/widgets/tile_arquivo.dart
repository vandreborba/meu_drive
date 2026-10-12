import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:meu_drive/dados/modelos/item_arquivo.dart';
import 'package:meu_drive/utils_geral/arquivos_aux.dart';

/// Linha de arquivo usada nas listas de busca e de últimos arquivos.
class TileArquivo extends StatelessWidget {
  final ItemArquivo item;
  final String? subtitulo;
  final VoidCallback? onTap;
  final Widget? acao;

  const TileArquivo({
    super.key,
    required this.item,
    this.subtitulo,
    this.onTap,
    this.acao,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        width: 46,
        height: 46,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _miniatura(context),
        ),
      ),
      title: Text(item.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitulo == null
          ? null
          : Text(subtitulo!, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: acao,
      onTap: onTap,
    );
  }

  Widget _miniatura(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    if (item.ehDiretorio) {
      return _caixaIcone(
        MdiIcons.folderOutline,
        esquema.primaryContainer,
        esquema.onPrimaryContainer,
      );
    }
    if (ehArquivoDeImagem(item.nome)) {
      return Image.file(
        File(item.caminho),
        fit: BoxFit.cover,
        cacheWidth: 160,
        errorBuilder: (_, _, _) => _caixaIcone(
          MdiIcons.imageBrokenVariant,
          esquema.surfaceContainerHighest,
          esquema.onSurfaceVariant,
        ),
      );
    }
    return _caixaIcone(
      iconeParaArquivo(item.nome),
      esquema.surfaceContainerHighest,
      esquema.onSurfaceVariant,
    );
  }

  Widget _caixaIcone(IconData icone, Color fundo, Color corIcone) {
    return Container(
      alignment: Alignment.center,
      color: fundo.withValues(alpha: 0.7),
      child: Icon(icone, size: 22, color: corIcone),
    );
  }
}
