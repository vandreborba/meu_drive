import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'package:meu_drive/dados/modelos/item_arquivo.dart';
import 'package:meu_drive/l10n/gerado/app_localizations.dart';
import 'package:meu_drive/utils_geral/abrir_item_aux.dart';
import 'package:meu_drive/utils_geral/caixa_dialogo.dart';
import 'package:meu_drive/utils_geral/formatadores_aux.dart';

/// Ações disponíveis no menu de um item do explorador.
enum AcaoArquivo { abrirCom, compartilhar, renomear, copiarCaminho, informacoes, excluir }

/// Executa [acao] sobre [item] e devolve `true` quando a listagem precisa ser
/// recarregada (ex.: após excluir ou renomear).
Future<bool> executarAcaoArquivo(
  BuildContext context,
  ItemArquivo item,
  AcaoArquivo acao,
  List<ItemArquivo> lista,
) async {
  switch (acao) {
    case AcaoArquivo.abrirCom:
      await abrirArquivo(context, item, lista);
      return false;
    case AcaoArquivo.compartilhar:
      await _compartilhar(context, item);
      return false;
    case AcaoArquivo.renomear:
      return _renomear(context, item);
    case AcaoArquivo.copiarCaminho:
      await _copiarCaminho(context, item);
      return false;
    case AcaoArquivo.informacoes:
      await _informacoes(context, item);
      return false;
    case AcaoArquivo.excluir:
      return _excluir(context, item);
  }
}

Future<void> _compartilhar(BuildContext context, ItemArquivo item) async {
  if (item.ehDiretorio) return;
  final textos = AppLocalizations.of(context);
  try {
    await SharePlus.instance.share(ShareParams(files: [XFile(item.caminho)]));
  } catch (_) {
    if (context.mounted) {
      MinhaCaixaDialogo.mostrarSnackBar(context, textos.falhaCompartilhar, erro: true);
    }
  }
}

Future<bool> _renomear(BuildContext context, ItemArquivo item) async {
  final textos = AppLocalizations.of(context);
  final novo = await MinhaCaixaDialogo.pedirTexto(
    context,
    titulo: textos.renomear,
    valorInicial: item.nome,
  );
  if (novo == null) return false;
  final nome = novo.trim();
  if (nome.isEmpty || nome.contains('/')) {
    if (context.mounted) {
      MinhaCaixaDialogo.mostrarSnackBar(context, textos.nomeInvalido, erro: true);
    }
    return false;
  }
  if (nome == item.nome) return false;
  final destino = '${item.pastaPai}/$nome';
  try {
    final existente = await FileSystemEntity.type(destino, followLinks: false);
    if (existente != FileSystemEntityType.notFound) {
      if (context.mounted) {
        MinhaCaixaDialogo.mostrarSnackBar(context, textos.nomeJaExiste, erro: true);
      }
      return false;
    }
    if (item.ehDiretorio) {
      await Directory(item.caminho).rename(destino);
    } else {
      await File(item.caminho).rename(destino);
    }
  } catch (_) {
    if (context.mounted) {
      MinhaCaixaDialogo.mostrarSnackBar(context, textos.falhaRenomear, erro: true);
    }
    return false;
  }
  return true;
}

Future<void> _copiarCaminho(BuildContext context, ItemArquivo item) async {
  final textos = AppLocalizations.of(context);
  await Clipboard.setData(ClipboardData(text: item.caminho));
  if (context.mounted) {
    MinhaCaixaDialogo.mostrarSnackBar(context, textos.caminhoCopiado);
  }
}

Future<void> _informacoes(BuildContext context, ItemArquivo item) async {
  final textos = AppLocalizations.of(context);
  final linhas = <String>[
    '${textos.infoNome}: ${item.nome}',
    '${textos.infoTipo}: ${item.ehDiretorio ? textos.tipoPastaNome : textos.tipoArquivoNome}',
    if (!item.ehDiretorio) '${textos.infoTamanho}: ${formatarBytes(item.tamanho)}',
    if (item.modificado != null)
      '${textos.infoModificado}: ${formatarDataHora(item.modificado!)}',
    '${textos.infoCaminho}: ${item.caminho}',
  ];
  await MinhaCaixaDialogo.informar(
    context,
    titulo: textos.informacoes,
    mensagem: linhas.join('\n'),
  );
}

Future<bool> _excluir(BuildContext context, ItemArquivo item) async {
  final textos = AppLocalizations.of(context);
  final confirmar = await MinhaCaixaDialogo.confirmar(
    context,
    titulo: textos.excluir,
    mensagem: textos.excluirItemMensagem(item.nome),
    textoConfirmar: textos.excluir,
  );
  if (!confirmar) return false;
  try {
    if (item.ehDiretorio) {
      await Directory(item.caminho).delete(recursive: true);
    } else {
      await File(item.caminho).delete();
    }
  } catch (_) {
    if (context.mounted) {
      MinhaCaixaDialogo.mostrarSnackBar(context, textos.falhaExcluir, erro: true);
    }
    return false;
  }
  if (context.mounted) {
    MinhaCaixaDialogo.mostrarSnackBar(context, textos.itemExcluido);
  }
  return true;
}
