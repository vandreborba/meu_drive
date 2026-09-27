import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:open_filex/open_filex.dart';

import 'package:meu_drive/l10n/gerado/app_localizations.dart';
import 'package:meu_drive/utils_geral/caixa_dialogo.dart';
import 'package:meu_drive/utils_geral/formatadores_aux.dart';

/// Visualizador de fotos em tela cheia, com zoom e opção de abrir em outro app.
///
/// Regras de gesto (para não confundir zoom com troca de foto):
/// - Sem zoom: arrastar troca de foto.
/// - Com zoom (pinça ou toque duplo): arrastar move a imagem; a troca de foto
///   fica desativada até voltar ao tamanho normal (toque duplo ou pinça).
class VisualizadorScreen extends StatefulWidget {
  final List<String> caminhos;
  final int indiceInicial;

  const VisualizadorScreen({super.key, required this.caminhos, this.indiceInicial = 0});

  @override
  State<VisualizadorScreen> createState() => _VisualizadorScreenState();
}

class _VisualizadorScreenState extends State<VisualizadorScreen> {
  late final PageController _pagina = PageController(initialPage: widget.indiceInicial);
  final TransformationController _transformacao = TransformationController();

  late int _indice = widget.indiceInicial;
  bool _ampliada = false;
  Offset _posicaoToque = Offset.zero;

  @override
  void initState() {
    super.initState();
    _transformacao.addListener(_aoTransformar);
  }

  @override
  void dispose() {
    _transformacao.removeListener(_aoTransformar);
    _transformacao.dispose();
    _pagina.dispose();
    super.dispose();
  }

  void _aoTransformar() {
    final ampliada = _transformacao.value.getMaxScaleOnAxis() > 1.01;
    if (ampliada != _ampliada) setState(() => _ampliada = ampliada);
  }

  void _reiniciarZoom() {
    if (!_ampliada) return;
    _transformacao.value = Matrix4.identity();
  }

  void _alternarZoom() {
    if (_ampliada) {
      _reiniciarZoom();
      return;
    }
    const escala = 2.5;
    final deslocamento = -_posicaoToque * (escala - 1);
    _transformacao.value = Matrix4.identity()
      ..translateByDouble(deslocamento.dx, deslocamento.dy, 0, 1)
      ..scaleByDouble(escala, escala, escala, 1);
  }

  String get _caminhoAtual => widget.caminhos[_indice];

  Future<void> _abrirComOutroApp() async {
    final resultado = await OpenFilex.open(_caminhoAtual);
    if (resultado.type != ResultType.done && mounted) {
      MinhaCaixaDialogo.mostrarSnackBar(
        context,
        AppLocalizations.of(context).arquivoNaoAbrir,
        erro: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = AppLocalizations.of(context);
    final esquema = Theme.of(context).colorScheme;
    final nome = _caminhoAtual.split('/').where((p) => p.isNotEmpty).last;
    final arquivo = File(_caminhoAtual);
    final existe = arquivo.existsSync();
    final tamanho = existe ? arquivo.lengthSync() : 0;
    final modificado = existe ? arquivo.lastModifiedSync() : null;

    return Scaffold(
      backgroundColor: esquema.surface,
      appBar: AppBar(
        title: Text(nome, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: textos.abrirCom,
            onPressed: _abrirComOutroApp,
            icon: const Icon(MdiIcons.openInNew),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pagina,
              physics: _ampliada
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              itemCount: widget.caminhos.length,
              onPageChanged: (indice) {
                _reiniciarZoom();
                setState(() => _indice = indice);
              },
              itemBuilder: (context, indice) => GestureDetector(
                onDoubleTapDown: (detalhes) => _posicaoToque = detalhes.localPosition,
                onDoubleTap: _alternarZoom,
                child: InteractiveViewer(
                  transformationController: _transformacao,
                  panEnabled: _ampliada,
                  scaleEnabled: true,
                  minScale: 1,
                  maxScale: 6,
                  child: Center(
                    child: Image.file(
                      File(widget.caminhos[indice]),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        MdiIcons.imageBrokenVariant,
                        size: 64,
                        color: esquema.outline,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: esquema.surfaceContainerHighest,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${formatarBytes(tamanho)}'
                    '${modificado != null ? ' · ${formatarData(modificado)}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Text(
                  _ampliada ? textos.ampliada : textos.toqueParaAmpliar,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                Text(
                  '${_indice + 1}/${widget.caminhos.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
