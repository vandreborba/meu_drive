import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils_geral/formatadores_aux.dart';
import '../modelos/dispositivo_syncthing.dart';
import '../modelos/estado_pasta.dart';
import '../modelos/pasta_syncthing.dart';
import '../servicos/armazenamento_servico.dart';
import '../servicos/ponte_motor_servico.dart';
import '../servicos/syncthing_rest_servico.dart';

/// Fase geral do motor de sincronização (embutido no app).
enum FaseMotor { verificando, iniciando, conectado, parado, erro }

/// Estado completo mostrado pela interface.
class EstadoMotor {
  final FaseMotor fase;
  final List<PastaSyncthing> pastas;
  final List<DispositivoSyncthing> dispositivos;
  final String? meuId;
  final String? meuNome;
  final Map<String, EstadoPasta> estados;
  final List<String> diagnostico;
  final String? erro;
  final DateTime? atualizadoEm;
  final bool temPermissaoArquivos;

  const EstadoMotor({
    required this.fase,
    this.pastas = const [],
    this.dispositivos = const [],
    this.meuId,
    this.meuNome,
    this.estados = const {},
    this.diagnostico = const [],
    this.erro,
    this.atualizadoEm,
    this.temPermissaoArquivos = false,
  });

  static const EstadoMotor inicial = EstadoMotor(fase: FaseMotor.verificando);

  /// Considera a sincronização pausada quando todas as pastas estão pausadas.
  bool get sincronizacaoPausada =>
      pastas.isNotEmpty && pastas.every((pasta) => pasta.pausada);

  EstadoMotor copyWith({
    FaseMotor? fase,
    List<PastaSyncthing>? pastas,
    List<DispositivoSyncthing>? dispositivos,
    String? meuId,
    String? meuNome,
    Map<String, EstadoPasta>? estados,
    List<String>? diagnostico,
    String? erro,
    bool limparErro = false,
    DateTime? atualizadoEm,
    bool? temPermissaoArquivos,
  }) {
    return EstadoMotor(
      fase: fase ?? this.fase,
      pastas: pastas ?? this.pastas,
      dispositivos: dispositivos ?? this.dispositivos,
      meuId: meuId ?? this.meuId,
      meuNome: meuNome ?? this.meuNome,
      estados: estados ?? this.estados,
      diagnostico: diagnostico ?? this.diagnostico,
      erro: limparErro ? null : (erro ?? this.erro),
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      temPermissaoArquivos: temPermissaoArquivos ?? this.temPermissaoArquivos,
    );
  }
}

/// Coordena iniciar o motor embutido, importar config, ler as pastas e
/// atualizar o estado.
class MotorNotifier extends Notifier<EstadoMotor> {
  final PonteMotorServico _ponte = PonteMotorServico();
  final ArmazenamentoServico _armazenamento = ArmazenamentoServico();

  SyncthingRestServico? _rest;
  Timer? _poll;

  @override
  EstadoMotor build() {
    ref.onDispose(() {
      _poll?.cancel();
      _rest?.fechar();
    });
    return EstadoMotor.inicial;
  }

  // ==================== REGISTRO ====================

  void _log(String linha) {
    debugPrint('[Motor] $linha');
    final agora = formatarHora(DateTime.now());
    final lista = [...state.diagnostico, '[$agora] $linha'];
    final limitada = lista.length > 200 ? lista.sublist(lista.length - 200) : lista;
    state = state.copyWith(diagnostico: limitada);
  }

  // ==================== CICLO DE VIDA ====================

  Future<void> inicializar() async {
    await atualizarPermissaoArquivos();
    state = state.copyWith(fase: FaseMotor.verificando, limparErro: true);
    _log('Preparando o motor...');
    if (!state.temPermissaoArquivos) {
      _log('Sem acesso a todos os arquivos: as pastas podem não aparecer.');
    }
    await _ponte.pedirNotificacoes();
    final importou = await _ponte.importarConfigMotor();
    if (importou) {
      _log('Configuração do Syncthing-Fork importada (mesmo device ID).');
    }
    await acordarEConectar();
  }

  Future<void> atualizarPermissaoArquivos() async {
    final tem = await _ponte.temTodosArquivos();
    state = state.copyWith(temPermissaoArquivos: tem);
  }

  Future<void> concederPermissaoArquivos() async {
    await _ponte.pedirTodosArquivos();
  }

  /// Inicia o motor embutido e conecta ao REST.
  Future<void> acordarEConectar() async {
    _pararPoll();
    _rest?.fechar();
    _rest = null;
    state = state.copyWith(fase: FaseMotor.iniciando, limparErro: true);

    _log('Iniciando o motor...');
    try {
      await _ponte.iniciarMotor();
    } catch (e) {
      // O Android só deixa iniciar o serviço com o app em primeiro plano.
      _log('Não foi possível iniciar o motor agora: $e');
      state = state.copyWith(
        fase: FaseMotor.erro,
        erro: 'O motor será iniciado quando o app estiver aberto.',
      );
      return;
    }

    final config = await _esperarConfigMotor();
    final porta = config?.porta ?? await _armazenamento.lerPortaGui();
    if (config?.endereco != null && config!.endereco!.isNotEmpty) {
      _log('Motor configurado em ${config.endereco}${config.tls ? ' (TLS)' : ''}.');
    } else {
      _log('Config do motor ainda não disponível; tentando a porta $porta.');
    }
    final rest = SyncthingRestServico(porta: porta)..definirApiKey(config?.apiKey);
    if (config != null) rest.definirTls(config.tls);

    try {
      _log('Aguardando o motor responder (porta $porta)...');
      await rest.esperarDisponivel();
    } on RespostaInvalida catch (e) {
      rest.fechar();
      _log('Falha de acesso: ${e.mensagem}');
      state = state.copyWith(fase: FaseMotor.erro, erro: e.mensagem);
      return;
    } on MotorIndisponivel catch (e) {
      for (final tentativa in rest.ultimasTentativas) {
        _log('Teste: ${tentativa.resumo}');
      }
      await _anexarLogMotor();
      rest.fechar();
      _log('Motor indisponível: ${e.mensagem}');
      state = state.copyWith(fase: FaseMotor.erro, erro: e.mensagem);
      return;
    } catch (e) {
      await _anexarLogMotor();
      rest.fechar();
      _log('Erro ao conectar: $e');
      state = state.copyWith(fase: FaseMotor.erro, erro: e.toString());
      return;
    }

    try {
      if (!rest.temApiKey) {
        rest.definirApiKey(await _ponte.lerApiKeyMotor());
      }
      _log(rest.temApiKey ? 'Usando a API key do motor.' : 'Sem API key; usando o handshake CSRF.');
      await rest.garantirAcesso();
      _log('Conectado. Lendo a configuração...');
      final pastas = await rest.listarPastas();
      final dispositivos = await rest.listarDispositivos();
      final meuId = await rest.meuDeviceId();
      _rest = rest;
      state = state.copyWith(
        fase: FaseMotor.conectado,
        pastas: pastas,
        dispositivos: dispositivos,
        meuId: meuId,
        meuNome: _nomeDoMeuAparelho(dispositivos, meuId),
        limparErro: true,
      );
      _log('Config lida: ${pastas.length} pasta(s), ${dispositivos.length} computador(es).');
      await _atualizarEstados();
      _iniciarPoll();
      try {
        await rest.rescan();
        _log('Verificação de mudanças solicitada.');
      } catch (_) {
        // Rescan é opcional; o motor detecta mudanças sozinho.
      }
    } catch (e) {
      await _anexarLogMotor();
      rest.fechar();
      _log('Falha ao ler a configuração: $e');
      state = state.copyWith(fase: FaseMotor.erro, erro: e.toString());
    }
  }

  /// Espera o `config.xml` do motor existir e devolve o endereço/API key dele.
  Future<ConfigMotor?> _esperarConfigMotor({Duration limite = const Duration(seconds: 30)}) async {
    final fim = DateTime.now().add(limite);
    while (DateTime.now().isBefore(fim)) {
      final config = await _ponte.lerConfigMotor();
      if (config != null && (config.endereco?.isNotEmpty ?? false)) return config;
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }
    return null;
  }

  /// Endereço efetivo do motor (do config.xml ou o fallback salvo).
  Future<String> lerEnderecoEfetivo() async {
    final config = await _ponte.lerConfigMotor();
    if (config != null && (config.endereco?.isNotEmpty ?? false)) return config.endereco!;
    final porta = await _armazenamento.lerPortaGui();
    return '127.0.0.1:$porta';
  }

  /// Copia as últimas linhas do log do motor para o diagnóstico do app.
  Future<void> _anexarLogMotor() async {
    final log = await _ponte.lerLogMotor();
    if (log.trim().isEmpty) {
      _log('Log do motor está vazio.');
      return;
    }
    for (final linha in log.split('\n')) {
      if (linha.trim().isNotEmpty) _log('motor> $linha');
    }
  }

  /// Ação do botão "Log do motor" no diagnóstico.
  Future<void> mostrarLogMotor() => _anexarLogMotor();

  Future<void> atualizarTudo() async {
    if (state.fase == FaseMotor.conectado) {
      await recarregarPastas();
      return;
    }
    await inicializar();
  }

  Future<void> recarregarPastas() async {
    final rest = _rest;
    if (rest == null) {
      await acordarEConectar();
      return;
    }
    try {
      final pastas = await rest.listarPastas();
      final dispositivos = await rest.listarDispositivos();
      final meuId = await rest.meuDeviceId();
      state = state.copyWith(
        pastas: pastas,
        dispositivos: dispositivos,
        meuId: meuId,
        meuNome: _nomeDoMeuAparelho(dispositivos, meuId),
        limparErro: true,
      );
      await _atualizarEstados();
    } catch (e) {
      _log('Falha ao recarregar: $e');
      state = state.copyWith(erro: e.toString());
    }
  }

  Future<void> verificarMudancas([String? id]) async {
    final rest = _rest;
    if (rest == null) return;
    try {
      await rest.rescan(id);
      _log('Verificação solicitada${id == null ? ' (todas)' : ''}.');
    } catch (e) {
      _log('Falha na verificação: $e');
    }
  }

  /// Para o motor embutido (o serviço em primeiro plano é encerrado).
  Future<void> pararMotor() async {
    _pararPoll();
    _rest?.fechar();
    _rest = null;
    await _ponte.pararMotor();
    _log('Motor parado.');
    state = state.copyWith(
      fase: FaseMotor.parado,
      pastas: const [],
      estados: const {},
      limparErro: true,
    );
  }

  /// Importa (substituindo) a configuração do Syncthing-Fork a partir de
  /// backups/syncthing/config.zip, preservando o mesmo device ID.
  Future<void> importarConfigDoSyncthingFork() async {
    await pararMotor();
    final importou = await _ponte.importarConfigMotor(forcar: true);
    _log(
      importou
          ? 'Configuração importada de backups/syncthing/config.zip.'
          : 'Não encontrei backups/syncthing/config.zip (exporte pelo Syncthing-Fork).',
    );
    await acordarEConectar();
  }

  /// Exporta a configuração do motor para backups/syncthing/config.zip.
  Future<bool> exportarConfig() async {
    final caminho = await _ponte.exportarConfigMotor();
    final exportou = caminho != null;
    _log(exportou
        ? 'Configurações exportadas para $caminho.'
        : 'Falha ao exportar as configurações.');
    return exportou;
  }

  /// Testa a conexão com o motor e registra cada tentativa no diagnóstico.
  Future<void> testarConexao() async {
    final config = await _ponte.lerConfigMotor();
    final porta = config?.porta ?? await _armazenamento.lerPortaGui();
    final rest = SyncthingRestServico(porta: porta)..definirApiKey(config?.apiKey);
    if (config != null) rest.definirTls(config.tls);
    _log('Testando conexão com o motor (porta $porta)...');
    final tentativas = await rest.testarConexao();
    for (final tentativa in tentativas) {
      _log('Teste: ${tentativa.resumo}');
    }
    if (tentativas.any((tentativa) => tentativa.ok)) {
      if (!rest.temApiKey) {
        rest.definirApiKey(await _ponte.lerApiKeyMotor());
      }
      try {
        await rest.garantirAcesso();
        final pastas = await rest.listarPastas();
        _log('Acesso OK: ${pastas.length} pasta(s) lidas.');
      } catch (e) {
        _log('Falha no acesso autenticado: $e');
      }
    }
    rest.fechar();
  }

  // ==================== GERENCIAMENTO (PASTAS E COMPUTADORES) ====================

  SyncthingRestServico _restObrigatorio() {
    final rest = _rest;
    if (rest == null) {
      throw const RespostaInvalida('O motor não está conectado.');
    }
    return rest;
  }

  Future<void> adicionarPasta({required String rotulo, required String caminho}) async {
    final rest = _restObrigatorio();
    final modelo = await rest.modeloPasta();
    modelo['id'] = _gerarIdPasta(rotulo);
    modelo['label'] = rotulo;
    modelo['path'] = caminho;
    modelo['type'] = 'sendreceive';
    modelo['paused'] = false;
    await rest.criarPasta(modelo);
    _log('Pasta "$rotulo" criada em $caminho.');
    await recarregarPastas();
  }

  Future<void> editarPasta(
    PastaSyncthing pasta, {
    String? rotulo,
    bool? pausada,
    String? tipo,
    List<String>? dispositivos,
  }) async {
    final rest = _restObrigatorio();
    final parcial = <String, dynamic>{};
    if (rotulo != null) parcial['label'] = rotulo;
    if (pausada != null) parcial['paused'] = pausada;
    if (tipo != null) parcial['type'] = tipo;
    if (dispositivos != null) {
      parcial['devices'] = dispositivos.map((id) => {'deviceID': id}).toList();
    }
    await rest.atualizarPasta(pasta.id, parcial);
    _log('Pasta ${pasta.nomeAmigavel} atualizada.');
    await recarregarPastas();
  }

  Future<void> excluirPasta(PastaSyncthing pasta) async {
    final rest = _restObrigatorio();
    await rest.excluirPasta(pasta.id);
    _log('Pasta ${pasta.nomeAmigavel} excluída.');
    await recarregarPastas();
  }

  Future<void> adicionarDispositivo({required String deviceId, required String nome}) async {
    final rest = _restObrigatorio();
    final modelo = await rest.modeloDispositivo();
    modelo['deviceID'] = deviceId;
    modelo['name'] = nome;
    await rest.criarDispositivo(modelo);
    _log('Computador "$nome" adicionado.');
    await recarregarPastas();
  }

  /// Nomeia este aparelho (aparece para os outros dispositivos).
  Future<void> renomearMeuAparelho(String nome) async {
    final rest = _restObrigatorio();
    final meuId = state.meuId;
    if (meuId == null) return;
    await rest.atualizarDispositivo(meuId, {'name': nome});
    await recarregarPastas();
  }

  /// Liga/desliga a sincronização em segundo plano (inverso de pausar).
  Future<void> manterSincronizado(bool ativo) async {
    if (ativo) {
      await retomarTudo();
    } else {
      await pausarTudo();
    }
  }

  /// Define o intervalo de verificação periódica (segundos; 0 = desativado).
  Future<void> definirRescanIntervalo(int segundos) async {
    final rest = _restObrigatorio();
    for (final pasta in state.pastas) {
      await rest.atualizarPasta(pasta.id, {'rescanIntervalS': segundos});
    }
    _log('Intervalo de verificação: $segundos s.');
    await recarregarPastas();
  }

  /// Liga/desliga a detecção de mudanças em tempo real (fs watcher).
  Future<void> definirFsWatcher(bool ativo) async {
    final rest = _restObrigatorio();
    for (final pasta in state.pastas) {
      await rest.atualizarPasta(pasta.id, {'fsWatcherEnabled': ativo});
    }
    _log('Detecção de mudanças: $ativo.');
    await recarregarPastas();
  }

  Future<void> pausarTudo() async {
    final rest = _restObrigatorio();
    await rest.pausarSistema();
    _log('Sincronização pausada.');
    await recarregarPastas();
  }

  Future<void> retomarTudo() async {
    final rest = _restObrigatorio();
    await rest.retomarSistema();
    _log('Sincronização retomada.');
    await recarregarPastas();
  }

  Future<void> renomearDispositivo(String deviceId, String nome) async {
    final rest = _restObrigatorio();
    await rest.atualizarDispositivo(deviceId, {'name': nome});
    await recarregarPastas();
  }

  Future<void> excluirDispositivo(String deviceId) async {
    final rest = _restObrigatorio();
    await rest.excluirDispositivo(deviceId);
    _log('Computador removido.');
    await recarregarPastas();
  }

  String? _nomeDoMeuAparelho(List<DispositivoSyncthing> dispositivos, String? meuId) {
    if (meuId == null) return null;
    for (final dispositivo in dispositivos) {
      if (dispositivo.id == meuId) return dispositivo.nome;
    }
    return null;
  }

  String _gerarIdPasta(String rotulo) {
    final base = rotulo
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final sufixo = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final curto = sufixo.length > 5 ? sufixo.substring(sufixo.length - 5) : sufixo;
    return '${base.isEmpty ? 'pasta' : base}-$curto';
  }

  Future<void> salvarPorta(int porta) async {
    await _armazenamento.salvarPortaGui(porta);
    await acordarEConectar();
  }

  Future<int> lerPorta() => _armazenamento.lerPortaGui();

  // ==================== POLL DE ESTADO ====================

  void _iniciarPoll() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _atualizarEstados());
  }

  void _pararPoll() {
    _poll?.cancel();
    _poll = null;
  }

  Future<void> _atualizarEstados() async {
    final rest = _rest;
    if (rest == null) return;
    final novos = <String, EstadoPasta>{};
    for (final pasta in state.pastas) {
      try {
        final status = await rest.statusPasta(pasta.id);
        novos[pasta.id] = EstadoPasta.doStatus(pasta, status);
      } catch (_) {
        novos[pasta.id] = EstadoPasta.desconhecido;
      }
    }
    state = state.copyWith(estados: novos, atualizadoEm: DateTime.now());
  }
}

final motorProvider = NotifierProvider<MotorNotifier, EstadoMotor>(MotorNotifier.new);
