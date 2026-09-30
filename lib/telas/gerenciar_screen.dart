import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:meu_drive/dados/modelos/dispositivo_syncthing.dart';
import 'package:meu_drive/dados/provedores/motor_provider.dart';
import 'package:meu_drive/l10n/gerado/app_localizations.dart';
import 'package:meu_drive/telas/escanear_qr_screen.dart';
import 'package:meu_drive/telas/explorador_screen.dart';
import 'package:meu_drive/telas/pasta_detalhe_screen.dart';
import 'package:meu_drive/utils_geral/caixa_dialogo.dart';
import 'package:meu_drive/utils_geral/espaco_aux.dart';
import 'package:meu_drive/widgets/selo_estado_pasta.dart';

/// Gerenciamento de pastas e computadores, em duas abas.
class GerenciarScreen extends ConsumerStatefulWidget {
  const GerenciarScreen({super.key});

  @override
  ConsumerState<GerenciarScreen> createState() => _GerenciarScreenState();
}

class _GerenciarScreenState extends ConsumerState<GerenciarScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _abas = TabController(length: 2, vsync: this)
    ..addListener(_aoTrocarAba);

  void _aoTrocarAba() {
    if (!_abas.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    _abas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textos = AppLocalizations.of(context);
    final estado = ref.watch(motorProvider);
    final abaPastas = _abas.index == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(textos.gerenciar),
        bottom: TabBar(
          controller: _abas,
          tabs: [
            Tab(text: textos.abaPastas),
            Tab(text: textos.abaComputadores),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: abaPastas ? _adicionarPasta : _adicionarComputador,
        icon: const Icon(MdiIcons.plus),
        label: Text(abaPastas ? textos.adicionarPasta : textos.adicionarComputador),
      ),
      body: TabBarView(
        controller: _abas,
        children: [
          _abaPastas(textos, estado),
          _abaComputadores(textos, estado),
        ],
      ),
    );
  }

  // ==================== PASTAS ====================

  Widget _abaPastas(AppLocalizations textos, EstadoMotor estado) {
    if (estado.pastas.isEmpty) {
      return Center(child: Text(textos.nenhumaPastaGerenciar));
    }
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 96 + espacoInferiorSistema(context)),
      children: [
        for (final pasta in estado.pastas)
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  MdiIcons.folderOutline,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(pasta.nomeAmigavel),
              subtitle: Text(
                '${pasta.caminho}\n${pasta.dispositivos.length} ${textos.compartilhadaCom}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              isThreeLine: true,
              trailing: SeloEstadoPasta(estado: estado.estados[pasta.id]),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PastaDetalheScreen(pasta: pasta),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _adicionarPasta() async {
    final textos = AppLocalizations.of(context);
    final caminho = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => ExploradorScreen(
          caminhoInicial: '/storage/emulated/0',
          titulo: textos.escolherPasta,
          selecionarPasta: true,
        ),
      ),
    );
    if (caminho == null || !mounted) return;

    final nome = await MinhaCaixaDialogo.pedirTexto(
      context,
      titulo: textos.nomeDaPasta,
      dica: caminho,
    );
    if (nome == null || nome.trim().isEmpty) return;

    try {
      await ref.read(motorProvider.notifier).adicionarPasta(
            rotulo: nome.trim(),
            caminho: caminho,
          );
      if (mounted) MinhaCaixaDialogo.mostrarSnackBar(context, textos.adicionarPasta);
    } catch (e) {
      if (mounted) MinhaCaixaDialogo.mostrarSnackBar(context, '$e', erro: true);
    }
  }

  // ==================== COMPUTADORES ====================

  Widget _abaComputadores(AppLocalizations textos, EstadoMotor estado) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 96 + espacoInferiorSistema(context)),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(MdiIcons.identifier),
            title: Text(textos.meuIdTitulo),
            subtitle: Text(estado.meuId ?? '-'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: textos.mostrarQr,
                  onPressed: estado.meuId == null ? null : () => _mostrarMeuQr(estado.meuId!),
                  icon: const Icon(MdiIcons.qrcode),
                ),
                IconButton(
                  tooltip: textos.copiarId,
                  onPressed: estado.meuId == null ? null : () => _copiarId(estado.meuId!),
                  icon: const Icon(MdiIcons.contentCopy),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (estado.dispositivos.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(textos.nenhumComputador, textAlign: TextAlign.center),
          )
        else
          for (final dispositivo in estado.dispositivos)
            Card(
              child: ListTile(
                leading: const Icon(MdiIcons.desktopClassic),
                title: Text(dispositivo.nome),
                subtitle: Text(dispositivo.idCurto),
                onTap: () => _opcoesDispositivo(dispositivo),
              ),
            ),
      ],
    );
  }

  Future<void> _adicionarComputador() async {
    final textos = AppLocalizations.of(context);
    final dados = await MinhaCaixaDialogo.personalizado<({String id, String nome})>(
      context,
      (_) => const _DialogoAdicionarComputador(),
    );
    if (dados == null || !mounted) return;

    final id = _normalizarId(dados.id);
    if (!_idValido(id)) {
      MinhaCaixaDialogo.mostrarSnackBar(context, textos.idInvalido, erro: true);
      return;
    }
    final nome = dados.nome.trim().isEmpty ? id.substring(0, 7) : dados.nome.trim();
    try {
      await ref.read(motorProvider.notifier).adicionarDispositivo(deviceId: id, nome: nome);
      if (mounted) MinhaCaixaDialogo.mostrarSnackBar(context, textos.adicionarComputador);
    } catch (e) {
      if (mounted) MinhaCaixaDialogo.mostrarSnackBar(context, '$e', erro: true);
    }
  }

  Future<void> _opcoesDispositivo(DispositivoSyncthing dispositivo) async {
    final textos = AppLocalizations.of(context);
    final escolha = await MinhaCaixaDialogo.escolher(
      context,
      titulo: dispositivo.nome,
      opcoes: [
        OpcaoDialogo(texto: textos.renomear, icone: MdiIcons.pencilOutline, primario: true),
        OpcaoDialogo(texto: textos.removerComputador, icone: MdiIcons.deleteOutline),
      ],
    );
    if (escolha == null || !mounted) return;
    if (escolha == 0) {
      final novo = await MinhaCaixaDialogo.pedirTexto(
        context,
        titulo: textos.renomear,
        valorInicial: dispositivo.nome,
      );
      if (novo == null || novo.trim().isEmpty) return;
      await ref.read(motorProvider.notifier).renomearDispositivo(dispositivo.id, novo.trim());
    } else if (escolha == 1) {
      final confirmou = await MinhaCaixaDialogo.confirmar(
        context,
        titulo: textos.removerComputador,
        mensagem: dispositivo.nome,
        textoConfirmar: textos.excluir,
      );
      if (!confirmou) return;
      await ref.read(motorProvider.notifier).excluirDispositivo(dispositivo.id);
    }
  }

  Future<void> _copiarId(String id) async {
    final textos = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: id));
    if (mounted) MinhaCaixaDialogo.mostrarSnackBar(context, textos.idCopiado);
  }

  Future<void> _mostrarMeuQr(String id) {
    final textos = AppLocalizations.of(context);
    return MinhaCaixaDialogo.personalizado<void>(
      context,
      (contexto) => AlertDialog(
        title: Text(textos.meuIdTitulo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(data: id, size: 220),
            const SizedBox(height: 12),
            SelectableText(id, style: Theme.of(contexto).textTheme.bodySmall),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(),
            child: Text(textos.ok),
          ),
        ],
      ),
    );
  }

  String _normalizarId(String bruto) => bruto.replaceAll(RegExp(r'\s'), '').toUpperCase();

  bool _idValido(String id) => RegExp(r'^[A-Z0-9]{7}(-[A-Z0-9]{7}){7}$').hasMatch(id);
}

// ==================== DIÁLOGO DE ADICIONAR COMPUTADOR ====================

class _DialogoAdicionarComputador extends StatefulWidget {
  const _DialogoAdicionarComputador();

  @override
  State<_DialogoAdicionarComputador> createState() => _DialogoAdicionarComputadorState();
}

class _DialogoAdicionarComputadorState extends State<_DialogoAdicionarComputador> {
  final TextEditingController _id = TextEditingController();
  final TextEditingController _nome = TextEditingController();

  @override
  void dispose() {
    _id.dispose();
    _nome.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textos = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(textos.adicionarComputador),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _id,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(labelText: textos.colarIdDispositivo),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nome,
              decoration: InputDecoration(labelText: textos.nomeDoComputador),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final codigo = await Navigator.of(context).push<String>(
                  MaterialPageRoute<String>(builder: (_) => const EscanearQrScreen()),
                );
                if (codigo != null) _id.text = codigo;
              },
              icon: const Icon(MdiIcons.qrcodeScan),
              label: Text(textos.escanearQr),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(textos.cancelar),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            (id: _id.text, nome: _nome.text),
          ),
          child: Text(textos.salvar),
        ),
      ],
    );
  }
}
