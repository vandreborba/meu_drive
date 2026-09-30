import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meu_drive/dados/modelos/estado_pasta.dart';
import 'package:meu_drive/dados/modelos/pasta_syncthing.dart';
import 'package:meu_drive/dados/provedores/atualizacao_provider.dart';
import 'package:meu_drive/dados/provedores/motor_provider.dart';
import 'package:meu_drive/l10n/gerado/app_localizations.dart';
import 'package:meu_drive/telas/configuracao_screen.dart';
import 'package:meu_drive/telas/explorador_screen.dart';
import 'package:meu_drive/telas/gerenciar_screen.dart';
import 'package:meu_drive/utils_geral/caixa_dialogo.dart';
import 'package:meu_drive/utils_geral/espaco_aux.dart';
import 'package:meu_drive/utils_geral/formatadores_aux.dart';
import 'package:meu_drive/widgets/cartao_atualizacao.dart';
import 'package:meu_drive/widgets/faixa_secao.dart';
import 'package:meu_drive/widgets/icone_estado_pasta.dart';

/// Tela principal: estado do motor, pastas compartilhadas e o aparelho.
class InicialScreen extends ConsumerStatefulWidget {
  const InicialScreen({super.key});

  @override
  ConsumerState<InicialScreen> createState() => _InicialScreenState();
}

class _InicialScreenState extends ConsumerState<InicialScreen> with WidgetsBindingObserver {
  static const String _caminhoCelular = '/storage/emulated/0';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(motorProvider.notifier).inicializar();
      ref.read(atualizacaoProvider.notifier).verificar();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final notificador = ref.read(motorProvider.notifier);
    notificador.atualizarPermissaoArquivos();
    final fase = ref.read(motorProvider).fase;
    if (fase == FaseMotor.precisaPermissao ||
        fase == FaseMotor.parado ||
        fase == FaseMotor.erro) {
      notificador.atualizarTudo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = AppLocalizations.of(context);
    final estado = ref.watch(motorProvider);
    final notificador = ref.read(motorProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(textos.appNome),
        actions: [
          IconButton(
            tooltip: textos.gerenciar,
            onPressed: () => _abrir(context, const GerenciarScreen()),
            icon: const Icon(MdiIcons.playlistEdit),
          ),
          IconButton(
            tooltip: textos.configuracao,
            onPressed: () => _abrir(context, const ConfiguracaoScreen()),
            icon: const Icon(MdiIcons.cogOutline),
          ),
        ],
      ),
      body: switch (estado.fase) {
        FaseMotor.verificando => _Progresso(texto: textos.verificandoMotor),
        FaseMotor.precisaPermissao => _CartaoMensagem(
            icone: MdiIcons.shieldAlertOutline,
            titulo: textos.permissaoTitulo,
            mensagem: textos.permissaoTexto,
            acoes: [
              FilledButton.icon(
                onPressed: notificador.concederPermissaoArquivos,
                icon: const Icon(MdiIcons.check),
                label: Text(textos.concederPermissao),
              ),
            ],
          ),
        FaseMotor.iniciando => _Progresso(texto: textos.iniciandoMotor),
        FaseMotor.parado => _Parado(onAcordar: notificador.acordarEConectar),
        FaseMotor.erro => _Erro(mensagem: estado.erro, onTentar: notificador.acordarEConectar),
        FaseMotor.conectado => _CorpoConectado(
            estado: estado,
            onExplorarCelular: () => _explorar(context, _caminhoCelular, textos.explorarCelular),
            onAbrirPasta: (pasta) => _explorar(context, pasta.caminho, pasta.nomeAmigavel),
            onConcederPermissao: notificador.concederPermissaoArquivos,
            onVerificar: notificador.verificarMudancas,
            onGerenciar: () => _abrir(context, const GerenciarScreen()),
          ),
      },
    );
  }

  void _abrir(BuildContext context, Widget tela) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => tela));
  }

  void _explorar(BuildContext context, String caminho, String titulo) {
    _abrir(context, ExploradorScreen(caminhoInicial: caminho, titulo: titulo));
  }
}

// ==================== ESTADOS SIMPLES ====================

class _Progresso extends StatelessWidget {
  final String texto;

  const _Progresso({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(texto, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _CartaoMensagem extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String mensagem;
  final List<Widget> acoes;

  const _CartaoMensagem({
    required this.icone,
    required this.titulo,
    required this.mensagem,
    this.acoes = const [],
  });

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icone, size: 48, color: esquema.primary),
                const SizedBox(height: 12),
                Text(titulo, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(mensagem, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                if (acoes.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: acoes),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Parado extends StatelessWidget {
  final Future<void> Function() onAcordar;

  const _Parado({required this.onAcordar});

  @override
  Widget build(BuildContext context) {
    final textos = AppLocalizations.of(context);
    return _CartaoMensagem(
      icone: MdiIcons.pauseCircleOutline,
      titulo: textos.desconectado,
      mensagem: textos.motorParadoTexto,
      acoes: [
        FilledButton.icon(
          onPressed: onAcordar,
          icon: const Icon(MdiIcons.power),
          label: Text(textos.acordarMotor),
        ),
      ],
    );
  }
}

class _Erro extends StatelessWidget {
  final String? mensagem;
  final Future<void> Function() onTentar;

  const _Erro({required this.mensagem, required this.onTentar});

  @override
  Widget build(BuildContext context) {
    final textos = AppLocalizations.of(context);
    return _CartaoMensagem(
      icone: MdiIcons.alertCircleOutline,
      titulo: textos.erroTitulo,
      mensagem: mensagem ?? textos.estadoDesconhecido,
      acoes: [
        FilledButton.icon(
          onPressed: onTentar,
          icon: const Icon(MdiIcons.refresh),
          label: Text(textos.tentarNovamente),
        ),
      ],
    );
  }
}

// ==================== CORPO CONECTADO ====================

class _CorpoConectado extends StatelessWidget {
  final EstadoMotor estado;
  final VoidCallback onExplorarCelular;
  final void Function(PastaSyncthing pasta) onAbrirPasta;
  final Future<void> Function() onConcederPermissao;
  final Future<void> Function([String? id]) onVerificar;
  final VoidCallback onGerenciar;

  const _CorpoConectado({
    required this.estado,
    required this.onExplorarCelular,
    required this.onAbrirPasta,
    required this.onConcederPermissao,
    required this.onVerificar,
    required this.onGerenciar,
  });

  @override
  Widget build(BuildContext context) {
    final textos = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: () => onVerificar(),
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + espacoInferiorSistema(context)),
        children: [
          if (!estado.temPermissaoArquivos) ...[
            _AvisoPermissao(onConceder: onConcederPermissao),
            const SizedBox(height: 12),
          ],
          _ResumoMotor(estado: estado),
          const CartaoAtualizacao(),
          const SizedBox(height: 18),
          FaixaSecao(titulo: textos.pastasCompartilhadas),
          if (estado.pastas.isEmpty)
            _VazioPastas(onAdicionar: onGerenciar)
          else
            for (final pasta in estado.pastas)
              _CartaoPasta(
                pasta: pasta,
                estadoPasta: estado.estados[pasta.id],
                onAbrir: () => onAbrirPasta(pasta),
                onVerificar: () => onVerificar(pasta.id),
              ),
          const SizedBox(height: 18),
          FaixaSecao(titulo: textos.esteAparelho),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  MdiIcons.cellphone,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              title: Text(textos.explorarCelular),
              trailing: const Icon(MdiIcons.chevronRight),
              onTap: onExplorarCelular,
            ),
          ),
          if (estado.atualizadoEm != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                '${textos.atualizadoEm} ${formatarHora(estado.atualizadoEm!)}',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _ResumoMotor extends StatelessWidget {
  final EstadoMotor estado;

  const _ResumoMotor({required this.estado});

  @override
  Widget build(BuildContext context) {
    final textos = AppLocalizations.of(context);
    final esquema = Theme.of(context).colorScheme;
    final sincronizando = estado.pastas.any(
      (pasta) => estado.estados[pasta.id]?.fase == FasePasta.sincronizando,
    );

    final IconData icone;
    final Color cor;
    final String titulo;
    if (estado.sincronizacaoPausada) {
      icone = MdiIcons.pauseCircleOutline;
      cor = esquema.outline;
      titulo = textos.sincronizacaoPausada;
    } else if (sincronizando) {
      icone = MdiIcons.sync;
      cor = esquema.tertiary;
      titulo = textos.sincronizandoAgora;
    } else {
      icone = MdiIcons.checkCircleOutline;
      cor = esquema.primary;
      titulo = textos.tudoSincronizado;
    }

    final totalBytes = estado.pastas.fold<int>(
      0,
      (soma, pasta) => soma + (estado.estados[pasta.id]?.bytes ?? 0),
    );
    final subtitulo = totalBytes > 0
        ? '${estado.pastas.length} ${textos.nPastas} · ${formatarBytes(totalBytes)}'
        : '${estado.pastas.length} ${textos.nPastas}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icone, color: cor, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitulo, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (sincronizando)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
          ],
        ),
      ),
    );
  }
}

class _VazioPastas extends StatelessWidget {
  final VoidCallback onAdicionar;

  const _VazioPastas({required this.onAdicionar});

  @override
  Widget build(BuildContext context) {
    final textos = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(textos.nenhumaPasta, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onAdicionar,
              icon: const Icon(MdiIcons.plus),
              label: Text(textos.adicionarPasta),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoPasta extends StatelessWidget {
  final PastaSyncthing pasta;
  final EstadoPasta? estadoPasta;
  final VoidCallback onAbrir;
  final VoidCallback onVerificar;

  const _CartaoPasta({
    required this.pasta,
    required this.estadoPasta,
    required this.onAbrir,
    required this.onVerificar,
  });

  @override
  Widget build(BuildContext context) {
    final textos = AppLocalizations.of(context);
    final partes = <String>[];
    final estadoDaPasta = estadoPasta;
    if (estadoDaPasta != null) {
      partes.add('${estadoDaPasta.itens} ${textos.itens}');
      if (estadoDaPasta.bytes > 0) partes.add(formatarBytes(estadoDaPasta.bytes));
    }
    if (pasta.dispositivos.isNotEmpty) {
      partes.add('${pasta.dispositivos.length} ${textos.compartilhadaCom}');
    }
    if (pasta.pausada) partes.add(textos.pausada);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            MdiIcons.folderOutline,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(pasta.nomeAmigavel),
        subtitle: Text(partes.join(' · ')),
        trailing: IconeEstadoPasta(estado: estadoPasta),
        onTap: onAbrir,
        onLongPress: () {
          MinhaCaixaDialogo.mostrarSnackBar(context, textos.rescan);
          onVerificar();
        },
      ),
    );
  }
}

class _AvisoPermissao extends StatelessWidget {
  final Future<void> Function() onConceder;

  const _AvisoPermissao({required this.onConceder});

  @override
  Widget build(BuildContext context) {
    final textos = AppLocalizations.of(context);
    final esquema = Theme.of(context).colorScheme;
    return Card(
      color: esquema.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(MdiIcons.shieldAlertOutline, color: esquema.onSecondaryContainer),
                const SizedBox(width: 8),
                Text(
                  textos.permissaoTitulo,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: esquema.onSecondaryContainer),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              textos.permissaoTexto,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: esquema.onSecondaryContainer),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onConceder, child: Text(textos.concederPermissao)),
          ],
        ),
      ),
    );
  }
}
