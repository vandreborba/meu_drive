import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import 'package:meu_drive/dados/provedores/explorador_prefs_provider.dart';
import 'package:meu_drive/l10n/gerado/app_localizations.dart';
import 'package:meu_drive/telas/visualizador_screen.dart';
import 'package:meu_drive/utils_geral/arquivos_aux.dart';
import 'package:meu_drive/utils_geral/caixa_dialogo.dart';
import 'package:meu_drive/utils_geral/espaco_aux.dart';
import 'package:meu_drive/utils_geral/formatadores_aux.dart';

/// Um nível navegado (pasta) dentro do explorador.
class _Nivel {
  final String caminho;
  final String rotulo;

  const _Nivel({required this.caminho, required this.rotulo});
}

class _ItemArquivo {
  final String nome;
  final String caminho;
  final bool ehDiretorio;
  final int tamanho;
  final DateTime? modificado;

  const _ItemArquivo({
    required this.nome,
    required this.caminho,
    required this.ehDiretorio,
    required this.tamanho,
    required this.modificado,
  });
}

/// Explorador de arquivos com trilha, miniaturas de fotos, ordenação e modos
/// de visualização (lista/grade).
class ExploradorScreen extends ConsumerStatefulWidget {
  final String caminhoInicial;
  final String titulo;

  /// Quando `true`, mostra um botão para devolver a pasta atual (seleção).
  final bool selecionarPasta;

  const ExploradorScreen({
    super.key,
    required this.caminhoInicial,
    required this.titulo,
    this.selecionarPasta = false,
  });

  @override
  ConsumerState<ExploradorScreen> createState() => _ExploradorScreenState();
}

class _ExploradorScreenState extends ConsumerState<ExploradorScreen> {
  final ScrollController _trilha = ScrollController();
  late final List<_Nivel> _pilha = [
    _Nivel(caminho: widget.caminhoInicial, rotulo: widget.titulo),
  ];

  List<_ItemArquivo> _itens = const [];
  bool _carregando = true;
  bool _mostrarOcultos = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _trilha.dispose();
    super.dispose();
  }

  // ==================== NAVEGAÇÃO ====================

  void _entrarNaPasta(_ItemArquivo item) {
    setState(() => _pilha.add(_Nivel(caminho: item.caminho, rotulo: item.nome)));
    _carregar();
  }

  void _irParaNivel(int indice) {
    if (indice >= _pilha.length - 1) return;
    setState(() => _pilha.removeRange(indice + 1, _pilha.length));
    _carregar();
  }

  bool _voltarNivel() {
    if (_pilha.length <= 1) return false;
    setState(() => _pilha.removeLast());
    _carregar();
    return true;
  }

  Future<void> _carregar() async {
    final caminho = _pilha.last.caminho;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final entradas = await Directory(caminho).list(followLinks: false).toList();
      final itens = <_ItemArquivo>[];
      for (final entrada in entradas) {
        final nome = entrada.path.split('/').where((p) => p.isNotEmpty).last;
        if (!_mostrarOcultos && nome.startsWith('.')) continue;
        try {
          final tipo = await FileSystemEntity.type(entrada.path, followLinks: false);
          if (tipo == FileSystemEntityType.directory) {
            itens.add(_ItemArquivo(
              nome: nome,
              caminho: entrada.path,
              ehDiretorio: true,
              tamanho: 0,
              modificado: null,
            ));
          } else if (tipo == FileSystemEntityType.file) {
            final stat = await File(entrada.path).stat();
            itens.add(_ItemArquivo(
              nome: nome,
              caminho: entrada.path,
              ehDiretorio: false,
              tamanho: stat.size,
              modificado: stat.modified,
            ));
          }
        } catch (_) {
          // Ignora entradas inacessíveis.
        }
      }
      if (!mounted) return;
      setState(() {
        _itens = itens;
        _carregando = false;
      });
      _rolarTrilhaParaOFim();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.toString();
        _carregando = false;
      });
    }
  }

  void _rolarTrilhaParaOFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_trilha.hasClients) {
        _trilha.jumpTo(_trilha.position.maxScrollExtent);
      }
    });
  }

  List<_ItemArquivo> _ordenar(List<_ItemArquivo> itens, ExploradorPrefs prefs) {
    final copia = [...itens];
    copia.sort((a, b) {
      if (a.ehDiretorio != b.ehDiretorio) return a.ehDiretorio ? -1 : 1;
      final int resultado;
      switch (prefs.ordenacao) {
        case OrdenacaoArquivo.nome:
          resultado = a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
        case OrdenacaoArquivo.data:
          resultado = (a.modificado ?? DateTime(0)).compareTo(b.modificado ?? DateTime(0));
        case OrdenacaoArquivo.tamanho:
          resultado = a.tamanho.compareTo(b.tamanho);
      }
      return prefs.ascendente ? resultado : -resultado;
    });
    return copia;
  }

  Future<void> _abrirItem(_ItemArquivo item) async {
    if (item.ehDiretorio) {
      _entrarNaPasta(item);
      return;
    }
    if (ehArquivoDeImagem(item.nome)) {
      final prefs = ref.read(exploradorPrefsProvider)[_pilha.last.caminho] ??
          const ExploradorPrefs();
      final imagens = _ordenar(_itens, prefs)
          .where((i) => !i.ehDiretorio && ehArquivoDeImagem(i.nome))
          .map((i) => i.caminho)
          .toList(growable: false);
      final indice = imagens.indexOf(item.caminho);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VisualizadorScreen(
            caminhos: imagens,
            indiceInicial: indice < 0 ? 0 : indice,
          ),
        ),
      );
      return;
    }
    final resultado = await OpenFilex.open(item.caminho);
    if (resultado.type != ResultType.done && mounted) {
      MinhaCaixaDialogo.mostrarSnackBar(
        context,
        AppLocalizations.of(context).arquivoNaoAbrir,
        erro: true,
      );
    }
  }

  // ==================== PREFERÊNCIAS ====================

  Future<void> _aoMenu(String valor) async {
    // As preferências de organização são por diretório.
    final caminho = _pilha.last.caminho;
    final prefs = ref.read(exploradorPrefsProvider.notifier);
    switch (valor) {
      case 'modo_lista':
        await prefs.definirModo(caminho, ModoVisualizacao.lista);
      case 'modo_grade':
        await prefs.definirModo(caminho, ModoVisualizacao.grade);
      case 'ord_nome':
        await prefs.definirOrdenacao(caminho, OrdenacaoArquivo.nome);
      case 'ord_data':
        await prefs.definirOrdenacao(caminho, OrdenacaoArquivo.data);
      case 'ord_tamanho':
        await prefs.definirOrdenacao(caminho, OrdenacaoArquivo.tamanho);
      case 'ord_asc':
        await prefs.definirAscendente(caminho, true);
      case 'ord_desc':
        await prefs.definirAscendente(caminho, false);
      case 'min_0':
        await prefs.definirTamanhoMiniatura(caminho, 0);
      case 'min_1':
        await prefs.definirTamanhoMiniatura(caminho, 1);
      case 'min_2':
        await prefs.definirTamanhoMiniatura(caminho, 2);
      case 'ocultos':
        setState(() => _mostrarOcultos = !_mostrarOcultos);
        await _carregar();
    }
  }

  // ==================== INTERFACE ====================

  @override
  Widget build(BuildContext context) {
    final textos = AppLocalizations.of(context);
    final prefs = ref.watch(exploradorPrefsProvider)[_pilha.last.caminho] ??
        const ExploradorPrefs();
    final itens = _ordenar(_itens, prefs);

    return PopScope(
      canPop: _pilha.length <= 1,
      onPopInvokedWithResult: (didPop, resultado) {
        if (!didPop) _voltarNivel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_pilha.last.rotulo),
          actions: [
            IconButton(
              tooltip: textos.atualizar,
              onPressed: _carregar,
              icon: const Icon(MdiIcons.refresh),
            ),
            if (widget.selecionarPasta)
              IconButton(
                tooltip: textos.usarEstaPasta,
                onPressed: () => Navigator.of(context).pop(_pilha.last.caminho),
                icon: const Icon(MdiIcons.check),
              ),
            _menuOpcoes(textos, prefs),
          ],
        ),
        body: Column(
          children: [
            _construirTrilha(context),
            if (!_carregando && _erro == null) _construirResumo(context, itens),
            Expanded(child: _construirCorpo(textos, prefs, itens)),
          ],
        ),
      ),
    );
  }

  Widget _menuOpcoes(AppLocalizations textos, ExploradorPrefs prefs) {
    PopupMenuItem<String> cabecalho(String texto) => PopupMenuItem<String>(
          enabled: false,
          height: 34,
          child: Text(
            texto,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        );

    return PopupMenuButton<String>(
      tooltip: textos.maisOpcoes,
      icon: const Icon(MdiIcons.dotsVertical),
      onSelected: _aoMenu,
      itemBuilder: (context) => [
        cabecalho(textos.verComo),
        CheckedPopupMenuItem(
          value: 'modo_lista',
          checked: prefs.modo == ModoVisualizacao.lista,
          child: Text(textos.modoLista),
        ),
        CheckedPopupMenuItem(
          value: 'modo_grade',
          checked: prefs.modo == ModoVisualizacao.grade,
          child: Text(textos.modoGrade),
        ),
        const PopupMenuDivider(),
        cabecalho(textos.ordenarPor),
        CheckedPopupMenuItem(
          value: 'ord_nome',
          checked: prefs.ordenacao == OrdenacaoArquivo.nome,
          child: Text(textos.ordenarNome),
        ),
        CheckedPopupMenuItem(
          value: 'ord_data',
          checked: prefs.ordenacao == OrdenacaoArquivo.data,
          child: Text(textos.ordenarData),
        ),
        CheckedPopupMenuItem(
          value: 'ord_tamanho',
          checked: prefs.ordenacao == OrdenacaoArquivo.tamanho,
          child: Text(textos.ordenarTamanho),
        ),
        CheckedPopupMenuItem(
          value: 'ord_asc',
          checked: prefs.ascendente,
          child: Text(textos.ordemCrescente),
        ),
        CheckedPopupMenuItem(
          value: 'ord_desc',
          checked: !prefs.ascendente,
          child: Text(textos.ordemDecrescente),
        ),
        const PopupMenuDivider(),
        cabecalho(textos.tamanhoMiniaturas),
        CheckedPopupMenuItem(
          value: 'min_0',
          checked: prefs.tamanhoMiniatura == 0,
          child: Text(textos.miniaturaPequena),
        ),
        CheckedPopupMenuItem(
          value: 'min_1',
          checked: prefs.tamanhoMiniatura == 1,
          child: Text(textos.miniaturaMedia),
        ),
        CheckedPopupMenuItem(
          value: 'min_2',
          checked: prefs.tamanhoMiniatura == 2,
          child: Text(textos.miniaturaGrande),
        ),
        const PopupMenuDivider(),
        CheckedPopupMenuItem(
          value: 'ocultos',
          checked: _mostrarOcultos,
          child: Text(textos.mostrarOcultos),
        ),
      ],
    );
  }

  Widget _construirTrilha(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: esquema.surfaceContainerHighest.withValues(alpha: 0.5),
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          controller: _trilha,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          itemCount: _pilha.length,
          separatorBuilder: (_, _) => Icon(
            MdiIcons.chevronRight,
            size: 18,
            color: esquema.outline,
          ),
          itemBuilder: (context, indice) {
            final ultimo = indice == _pilha.length - 1;
            return Center(
              child: InkWell(
                onTap: ultimo ? null : () => _irParaNivel(indice),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Text(
                    _pilha[indice].rotulo,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ultimo ? esquema.onSurface : esquema.primary,
                          fontWeight: ultimo ? FontWeight.w600 : FontWeight.normal,
                        ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _construirResumo(BuildContext context, List<_ItemArquivo> itens) {
    final textos = AppLocalizations.of(context);
    final pastas = itens.where((item) => item.ehDiretorio).length;
    final arquivos = itens.length - pastas;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$pastas ${textos.nPastas} · $arquivos ${textos.nArquivos}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  Widget _construirCorpo(
    AppLocalizations textos,
    ExploradorPrefs prefs,
    List<_ItemArquivo> itens,
  ) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(MdiIcons.folderAlertOutline, size: 48),
              const SizedBox(height: 12),
              Text(_erro!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _carregar, child: Text(textos.tentarNovamente)),
            ],
          ),
        ),
      );
    }
    if (itens.isEmpty) {
      return Center(child: Text(textos.vazio));
    }
    return prefs.modo == ModoVisualizacao.grade
        ? _construirGrade(prefs, itens)
        : _construirLista(textos, itens, prefs);
  }

  Widget _construirGrade(ExploradorPrefs prefs, List<_ItemArquivo> itens) {
    final colunas = prefs.tamanhoMiniatura == 0
        ? 4
        : prefs.tamanhoMiniatura == 1
            ? 3
            : 2;
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(10, 10, 10, 10 + espacoInferiorSistema(context)),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: colunas,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: itens.length,
      itemBuilder: (context, indice) {
        final item = itens[indice];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _abrirItem(item),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _miniatura(context, item, prefs),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (!item.ehDiretorio)
                Text(
                  formatarBytes(item.tamanho),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _construirLista(
    AppLocalizations textos,
    List<_ItemArquivo> itens,
    ExploradorPrefs prefs,
  ) {
    return ListView.builder(
      padding: EdgeInsets.only(top: 4, bottom: 4 + espacoInferiorSistema(context)),
      itemCount: itens.length,
      itemBuilder: (context, indice) {
        final item = itens[indice];
        return ListTile(
          leading: SizedBox(
            width: 46,
            height: 46,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _miniatura(context, item, prefs),
            ),
          ),
          title: Text(item.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: item.ehDiretorio
              ? null
              : Text(
                  '${formatarBytes(item.tamanho)}'
                  '${item.modificado != null ? ' · ${formatarData(item.modificado!)}' : ''}',
                ),
          trailing: item.ehDiretorio ? const Icon(MdiIcons.chevronRight, size: 20) : null,
          onTap: () => _abrirItem(item),
        );
      },
    );
  }

  Widget _miniatura(BuildContext context, _ItemArquivo item, ExploradorPrefs prefs) {
    final esquema = Theme.of(context).colorScheme;
    if (item.ehDiretorio) {
      return _caixaIcone(MdiIcons.folderOutline, esquema.primaryContainer, esquema.onPrimaryContainer);
    }
    if (ehArquivoDeImagem(item.nome)) {
      final largura = prefs.tamanhoMiniatura == 0
          ? 160
          : prefs.tamanhoMiniatura == 1
              ? 260
              : 420;
      return Image.file(
        File(item.caminho),
        fit: BoxFit.cover,
        cacheWidth: largura,
        errorBuilder: (_, _, _) => _caixaIcone(
          MdiIcons.imageBrokenVariant,
          esquema.surfaceContainerHighest,
          esquema.onSurfaceVariant,
        ),
      );
    }
    return _caixaIcone(
      _iconeDoItem(item),
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

  IconData _iconeDoItem(_ItemArquivo item) {
    if (item.ehDiretorio) return MdiIcons.folderOutline;
    final nome = item.nome.toLowerCase();
    if (ehArquivoDeImagem(nome)) return MdiIcons.imageOutline;
    if (nome.endsWith('.mp4') || nome.endsWith('.mkv') || nome.endsWith('.mov') || nome.endsWith('.avi')) {
      return MdiIcons.videoOutline;
    }
    if (nome.endsWith('.mp3') || nome.endsWith('.ogg') || nome.endsWith('.wav') || nome.endsWith('.m4a')) {
      return MdiIcons.musicNoteOutline;
    }
    if (nome.endsWith('.pdf')) return MdiIcons.filePdfBox;
    if (nome.endsWith('.zip') || nome.endsWith('.rar') || nome.endsWith('.7z')) {
      return MdiIcons.zipBoxOutline;
    }
    return MdiIcons.fileOutline;
  }
}
