import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meu_drive/dados/modelos/pasta_syncthing.dart';
import 'package:meu_drive/dados/provedores/motor_provider.dart';
import 'package:meu_drive/l10n/gerado/app_localizations.dart';
import 'package:meu_drive/utils_geral/caixa_dialogo.dart';

/// Edição de uma pasta: nome, tipo, pausa, compartilhamento e exclusão.
class PastaDetalheScreen extends ConsumerStatefulWidget {
  final PastaSyncthing pasta;

  const PastaDetalheScreen({super.key, required this.pasta});

  @override
  ConsumerState<PastaDetalheScreen> createState() => _PastaDetalheScreenState();
}

class _PastaDetalheScreenState extends ConsumerState<PastaDetalheScreen> {
  late final TextEditingController _nome =
      TextEditingController(text: widget.pasta.nomeAmigavel);
  late String _tipo = widget.pasta.tipo;
  late bool _pausada = widget.pasta.pausada;
  late final Set<String> _compartilhados = widget.pasta.dispositivos.toSet();
  bool _salvando = false;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textos = AppLocalizations.of(context);
    final estado = ref.watch(motorProvider);
    final pasta = widget.pasta;

    return Scaffold(
      appBar: AppBar(
        title: Text(pasta.nomeAmigavel),
        actions: [
          IconButton(
            tooltip: textos.salvar,
            onPressed: _salvando ? null : _salvar,
            icon: const Icon(MdiIcons.contentSaveOutline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nome,
            decoration: InputDecoration(
              labelText: textos.nomeDaPasta,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(MdiIcons.folderOutline),
            title: Text(textos.caminhoDaPasta),
            subtitle: Text(pasta.caminho),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _tipo,
            decoration: InputDecoration(
              labelText: textos.tipoPasta,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: 'sendreceive', child: Text(textos.tipoEnviarReceber)),
              DropdownMenuItem(value: 'sendonly', child: Text(textos.tipoSomenteEnviar)),
              DropdownMenuItem(value: 'receiveonly', child: Text(textos.tipoSomenteReceber)),
            ],
            onChanged: (valor) {
              if (valor != null) setState(() => _tipo = valor);
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(textos.pausarPasta),
            value: _pausada,
            onChanged: (valor) => setState(() => _pausada = valor),
          ),
          const Divider(),
          Text(textos.compartilharCom, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (estado.dispositivos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(textos.nenhumComputador),
            )
          else
            ...estado.dispositivos.map(
              (dispositivo) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(dispositivo.nome),
                subtitle: Text(dispositivo.idCurto),
                value: _compartilhados.contains(dispositivo.id),
                onChanged: (marcado) {
                  setState(() {
                    if (marcado == true) {
                      _compartilhados.add(dispositivo.id);
                    } else {
                      _compartilhados.remove(dispositivo.id);
                    }
                  });
                },
              ),
            ),
          const Divider(),
          OutlinedButton.icon(
            onPressed: _salvando ? null : _excluir,
            icon: const Icon(MdiIcons.deleteOutline),
            label: Text(textos.excluir),
          ),
        ],
      ),
    );
  }

  Future<void> _salvar() async {
    final textos = AppLocalizations.of(context);
    setState(() => _salvando = true);
    try {
      await ref.read(motorProvider.notifier).editarPasta(
            widget.pasta,
            rotulo: _nome.text.trim().isEmpty ? widget.pasta.nomeAmigavel : _nome.text.trim(),
            tipo: _tipo,
            pausada: _pausada,
            dispositivos: _compartilhados.toList(),
          );
      if (mounted) {
        MinhaCaixaDialogo.mostrarSnackBar(context, textos.salvar);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        MinhaCaixaDialogo.mostrarSnackBar(context, '$e', erro: true);
        setState(() => _salvando = false);
      }
    }
  }

  Future<void> _excluir() async {
    final textos = AppLocalizations.of(context);
    final confirmou = await MinhaCaixaDialogo.confirmar(
      context,
      titulo: textos.excluirPastaTitulo,
      mensagem: textos.excluirPastaMensagem,
      textoConfirmar: textos.excluir,
    );
    if (!confirmou) return;
    setState(() => _salvando = true);
    try {
      await ref.read(motorProvider.notifier).excluirPasta(widget.pasta);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        MinhaCaixaDialogo.mostrarSnackBar(context, '$e', erro: true);
        setState(() => _salvando = false);
      }
    }
  }
}
