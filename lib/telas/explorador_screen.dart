import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:open_filex/open_filex.dart';

import 'package:meu_drive/l10n/gerado/app_localizations.dart';
import 'package:meu_drive/utils_geral/caixa_dialogo.dart';
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

/// Explorador de arquivos com trilha de navegação (breadcrumb).
class ExploradorScreen extends StatefulWidget {
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
  State<ExploradorScreen> createState() => _ExploradorScreenState();
}

class _ExploradorScreenState extends State<ExploradorScreen> {
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
        // Esconde itens internos do Syncthing (.st*, .trashed-*) e dotfiles.
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
      itens.sort((a, b) {
        if (a.ehDiretorio != b.ehDiretorio) return a.ehDiretorio ? -1 : 1;
        return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
      });
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

  Future<void> _abrirItem(_ItemArquivo item) async {
    if (item.ehDiretorio) {
      _entrarNaPasta(item);
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

  // ==================== INTERFACE ====================

  @override
  Widget build(BuildContext context) {
    final textos = AppLocalizations.of(context);
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
              tooltip: _mostrarOcultos ? textos.ocultarOcultos : textos.mostrarOcultos,
              onPressed: () {
                setState(() => _mostrarOcultos = !_mostrarOcultos);
                _carregar();
              },
              icon: Icon(_mostrarOcultos ? MdiIcons.eyeOffOutline : MdiIcons.eyeOutline),
            ),
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
          ],
        ),
        body: Column(
          children: [
            _construirTrilha(context),
            if (!_carregando && _erro == null) _construirResumo(context),
            Expanded(child: _construirCorpo(textos)),
          ],
        ),
      ),
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

  Widget _construirResumo(BuildContext context) {
    final textos = AppLocalizations.of(context);
    final pastas = _itens.where((item) => item.ehDiretorio).length;
    final arquivos = _itens.length - pastas;
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

  Widget _construirCorpo(AppLocalizations textos) {
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
    if (_itens.isEmpty) {
      return Center(child: Text(textos.vazio));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _itens.length,
      itemBuilder: (context, indice) {
        final item = _itens[indice];
        final esquema = Theme.of(context).colorScheme;
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (item.ehDiretorio ? esquema.primaryContainer : esquema.surfaceContainerHighest)
                  .withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _iconeDoItem(item),
              size: 22,
              color: item.ehDiretorio ? esquema.onPrimaryContainer : esquema.onSurfaceVariant,
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

  IconData _iconeDoItem(_ItemArquivo item) {
    if (item.ehDiretorio) return MdiIcons.folderOutline;
    final nome = item.nome.toLowerCase();
    if (nome.endsWith('.jpg') ||
        nome.endsWith('.jpeg') ||
        nome.endsWith('.png') ||
        nome.endsWith('.gif') ||
        nome.endsWith('.webp')) {
      return MdiIcons.imageOutline;
    }
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
