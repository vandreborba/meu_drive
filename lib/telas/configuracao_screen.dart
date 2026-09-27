import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meu_drive/dados/provedores/atualizacao_provider.dart';
import 'package:meu_drive/dados/provedores/motor_provider.dart';
import 'package:meu_drive/dados/provedores/tema_provider.dart';
import 'package:meu_drive/l10n/gerado/app_localizations.dart';
import 'package:meu_drive/utils_geral/caixa_dialogo.dart';
import 'package:meu_drive/utils_geral/rotulos_aux.dart';
import 'package:meu_drive/widgets/cartao_atualizacao.dart';

/// Configurações do usuário, com as opções técnicas recolhidas em "Avançado".
class ConfiguracaoScreen extends ConsumerStatefulWidget {
  const ConfiguracaoScreen({super.key});

  @override
  ConsumerState<ConfiguracaoScreen> createState() => _ConfiguracaoScreenState();
}

class _ConfiguracaoScreenState extends ConsumerState<ConfiguracaoScreen> {
  String? _endereco;
  String? _versao;

  @override
  void initState() {
    super.initState();
    _carregarEndereco();
    ref.read(atualizacaoProvider.notifier).versaoAtual().then((valor) {
      if (mounted) setState(() => _versao = valor);
    });
  }

  Future<void> _verificarAtualizacoes() async {
    final textos = AppLocalizations.of(context);
    await ref.read(atualizacaoProvider.notifier).verificar();
    if (!mounted) return;
    if (ref.read(atualizacaoProvider).disponivel == null) {
      MinhaCaixaDialogo.mostrarSnackBar(context, textos.tudoAtualizado);
      return;
    }
    await executarAtualizacao(context, ref);
  }

  Future<void> _carregarEndereco() async {
    final endereco = await ref.read(motorProvider.notifier).lerEnderecoEfetivo();
    if (mounted) setState(() => _endereco = endereco);
  }

  @override
  Widget build(BuildContext context) {
    final textos = AppLocalizations.of(context);
    final estado = ref.watch(motorProvider);
    final notificador = ref.read(motorProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(textos.configuracao)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _titulo(context, textos.geral),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(MdiIcons.themeLightDark),
                  title: Text(textos.tema),
                  subtitle: Text(_rotuloTema(textos, ref.watch(temaProvider))),
                  onTap: _escolherTema,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(MdiIcons.cellphone),
                  title: Text(textos.nomeDesteAparelho),
                  subtitle: Text(estado.meuNome ?? estado.meuId ?? '-'),
                  onTap: estado.meuId == null ? null : _renomearAparelho,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(MdiIcons.rocketLaunchOutline),
                  title: Text(textos.verificarAtualizacoes),
                  subtitle: Text(_versao == null ? '' : 'v$_versao'),
                  onTap: _verificarAtualizacoes,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _titulo(context, textos.sincronizacao),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(MdiIcons.cloudSyncOutline),
                  title: Text(textos.manterSincronizado),
                  value: !estado.sincronizacaoPausada,
                  onChanged: _conectado ? _alternarManterSincronizado : null,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(MdiIcons.eyeOutline),
                  title: Text(textos.detectarMudancas),
                  value: _fsWatcherAtivo,
                  onChanged: _conectado ? _alternarFsWatcher : null,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(MdiIcons.clockOutline),
                  title: Text(textos.verificarACada),
                  subtitle: Text(_rotuloIntervalo(textos, _rescanSegundos)),
                  onTap: _conectado ? _escolherIntervalo : null,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(MdiIcons.folderRefreshOutline),
                  title: Text(textos.rescan),
                  onTap: () => notificador.verificarMudancas(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _titulo(context, textos.permissaoArquivos),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const Icon(MdiIcons.shieldCheckOutline),
              title: Text(textos.permissaoArquivos),
              subtitle: Text(
                estado.temPermissaoArquivos ? textos.concedido : textos.naoConcedido,
              ),
              trailing: estado.temPermissaoArquivos
                  ? const Icon(MdiIcons.check)
                  : FilledButton(
                      onPressed: notificador.concederPermissaoArquivos,
                      child: Text(textos.concederPermissao),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          _titulo(context, textos.backup),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(MdiIcons.exportVariant),
                  title: Text(textos.exportarConfig),
                  onTap: _exportarConfig,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(MdiIcons.import),
                  title: Text(textos.importarConfig),
                  onTap: _importarConfig,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              leading: const Icon(MdiIcons.tuneVariant),
              title: Text(textos.avancado),
              childrenPadding: const EdgeInsets.only(bottom: 8),
              children: [
                ListTile(
                  leading: const Icon(MdiIcons.refresh),
                  title: Text(textos.recarregarTudo),
                  subtitle: Text(rotuloFaseMotor(textos, estado.fase)),
                  onTap: notificador.acordarEConectar,
                ),
                ListTile(
                  leading: const Icon(MdiIcons.lanConnect),
                  title: Text(textos.portaGui),
                  subtitle: Text(_endereco ?? '-'),
                ),
                ListTile(
                  leading: const Icon(MdiIcons.power),
                  title: Text(textos.pararMotor),
                  enabled: estado.fase == FaseMotor.conectado,
                  onTap: notificador.pararMotor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _titulo(BuildContext context, String texto) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        texto.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.8,
            ),
      ),
    );
  }

  bool get _conectado => ref.read(motorProvider).fase == FaseMotor.conectado;

  bool get _fsWatcherAtivo {
    final pastas = ref.read(motorProvider).pastas;
    return pastas.isEmpty || pastas.every((pasta) => pasta.fsWatcherEnabled);
  }

  int get _rescanSegundos {
    final pastas = ref.read(motorProvider).pastas;
    return pastas.isEmpty ? 3600 : pastas.first.rescanIntervaloS;
  }

  String _rotuloIntervalo(AppLocalizations textos, int segundos) {
    if (segundos <= 0) return textos.desativado;
    final horas = segundos ~/ 3600;
    return horas <= 1 ? '1 ${textos.hora}' : '$horas ${textos.horas}';
  }

  Future<void> _alternarManterSincronizado(bool ativo) async {
    try {
      await ref.read(motorProvider.notifier).manterSincronizado(ativo);
    } catch (e) {
      if (mounted) {
        MinhaCaixaDialogo.mostrarSnackBar(context, '$e', erro: true);
      }
    }
  }

  Future<void> _alternarFsWatcher(bool ativo) async {
    try {
      await ref.read(motorProvider.notifier).definirFsWatcher(ativo);
    } catch (e) {
      if (mounted) {
        MinhaCaixaDialogo.mostrarSnackBar(context, '$e', erro: true);
      }
    }
  }

  Future<void> _escolherIntervalo() async {
    final textos = AppLocalizations.of(context);
    final atual = _rescanSegundos;
    const valores = [0, 3600, 10800, 21600, 43200, 86400];
    final escolha = await MinhaCaixaDialogo.escolher(
      context,
      titulo: textos.verificarACada,
      opcoes: [
        for (final valor in valores)
          OpcaoDialogo(
            texto: _rotuloIntervalo(textos, valor),
            icone: MdiIcons.clockOutline,
            primario: valor == atual,
          ),
      ],
    );
    if (escolha == null) return;
    try {
      await ref.read(motorProvider.notifier).definirRescanIntervalo(valores[escolha]);
    } catch (e) {
      if (mounted) {
        MinhaCaixaDialogo.mostrarSnackBar(context, '$e', erro: true);
      }
    }
  }

  String _rotuloTema(AppLocalizations textos, ThemeMode modo) {
    return switch (modo) {
      ThemeMode.light => textos.temaClaro,
      ThemeMode.dark => textos.temaEscuro,
      ThemeMode.system => textos.temaSistema,
    };
  }

  Future<void> _escolherTema() async {
    final textos = AppLocalizations.of(context);
    final atual = ref.read(temaProvider);
    final escolha = await MinhaCaixaDialogo.escolher(
      context,
      titulo: textos.tema,
      opcoes: [
        OpcaoDialogo(texto: textos.temaSistema, icone: MdiIcons.themeLightDark, primario: atual == ThemeMode.system),
        OpcaoDialogo(texto: textos.temaClaro, icone: MdiIcons.whiteBalanceSunny, primario: atual == ThemeMode.light),
        OpcaoDialogo(texto: textos.temaEscuro, icone: MdiIcons.weatherNight, primario: atual == ThemeMode.dark),
      ],
    );
    if (escolha == null) return;
    final modo = switch (escolha) {
      0 => ThemeMode.system,
      1 => ThemeMode.light,
      _ => ThemeMode.dark,
    };
    await ref.read(temaProvider.notifier).definir(modo);
  }

  Future<void> _renomearAparelho() async {
    final textos = AppLocalizations.of(context);
    final estado = ref.read(motorProvider);
    final nome = await MinhaCaixaDialogo.pedirTexto(
      context,
      titulo: textos.nomeDesteAparelho,
      valorInicial: estado.meuNome ?? '',
    );
    if (nome == null || nome.trim().isEmpty) return;
    try {
      await ref.read(motorProvider.notifier).renomearMeuAparelho(nome.trim());
      if (mounted) MinhaCaixaDialogo.mostrarSnackBar(context, textos.nomeDesteAparelho);
    } catch (e) {
      if (mounted) MinhaCaixaDialogo.mostrarSnackBar(context, '$e', erro: true);
    }
  }

  Future<void> _exportarConfig() async {
    final textos = AppLocalizations.of(context);
    final exportou = await ref.read(motorProvider.notifier).exportarConfig();
    if (!mounted) return;
    MinhaCaixaDialogo.mostrarSnackBar(
      context,
      exportou ? textos.exportarConfigFeito : textos.exportarConfigFalhou,
      erro: !exportou,
    );
  }

  Future<void> _importarConfig() async {
    final textos = AppLocalizations.of(context);
    final confirmou = await MinhaCaixaDialogo.confirmar(
      context,
      titulo: textos.importarConfigTitulo,
      mensagem: textos.importarConfigMensagem,
      textoConfirmar: textos.importarConfig,
    );
    if (!confirmou) return;
    await ref.read(motorProvider.notifier).importarConfigDoSyncthingFork();
    if (mounted) {
      MinhaCaixaDialogo.mostrarSnackBar(context, textos.importarConfig);
      await _carregarEndereco();
    }
  }
}
