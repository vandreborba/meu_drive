import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../modelos/dispositivo_syncthing.dart';
import '../modelos/pasta_syncthing.dart';

/// Resposta HTTP simples (código + corpo em texto).
class RespostaRest {
  final int codigo;
  final String corpo;

  const RespostaRest(this.codigo, this.corpo);

  bool get ok => codigo >= 200 && codigo < 300;
}

/// O motor não ficou disponível dentro do tempo esperado.
class MotorIndisponivel implements Exception {
  final String mensagem;

  const MotorIndisponivel(this.mensagem);

  @override
  String toString() => mensagem;
}

/// O motor respondeu, mas a negociação de acesso falhou (ex.: GUI com usuário
/// e senha e sem API key disponível).
class RespostaInvalida implements Exception {
  final String mensagem;

  const RespostaInvalida(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Resultado de uma tentativa de conexão, usado no diagnóstico.
class TentativaConexao {
  final String url;
  final bool ok;
  final String detalhe;

  const TentativaConexao({required this.url, required this.ok, required this.detalhe});

  String get resumo => '${ok ? 'ok' : 'falhou'}  $url${detalhe.isEmpty ? '' : '  ($detalhe)'}';
}

/// Cliente REST do motor, acessado por localhost.
///
/// Acesso preferencial: header `X-API-Key` (lido do `config.xml` do motor).
/// Alternativa: handshake CSRF documentado (cookie `CSRF-Token-<unique>` +
/// header `X-CSRF-Token-<unique>`), usado pela interface web.
///
/// O GUI escuta só em loopback. Builds de release usam a porta 8384 e builds de
/// depuração usam 8385; o schema pode ser HTTPS ou HTTP. Por isso testamos as
/// combinações.
class SyncthingRestServico {
  static const int portaPadrao = 8384;

  /// Builds de depuração do Syncthing-Fork usam esta porta.
  static const int portaDebug = 8385;

  final String host;
  final int porta;

  HttpClient? _cliente;
  String? _esquemaAtivo;
  String? _hostAtivo;
  int? _portaAtiva;
  String? _nomeTokenCsrf;
  String? _valorTokenCsrf;
  String? _apiKey;
  String? _esquemaPreferido;
  List<TentativaConexao> _ultimasTentativas = const [];

  SyncthingRestServico({this.host = '127.0.0.1', this.porta = portaPadrao});

  bool get conectado => _cliente != null && (_apiKey != null || _nomeTokenCsrf != null);

  List<TentativaConexao> get ultimasTentativas => _ultimasTentativas;

  bool get temApiKey => _apiKey != null;

  /// Define a API key lida do `config.xml` do motor.
  void definirApiKey(String? chave) {
    _apiKey = (chave != null && chave.trim().isNotEmpty) ? chave.trim() : null;
  }

  /// Informa se o GUI usa TLS (lido do `config.xml`).
  void definirTls(bool tls) {
    _esquemaPreferido = tls ? 'https' : 'http';
  }

  List<int> get _portas => <int>{porta, portaPadrao, portaDebug}.toList(growable: false);

  List<String> get _esquemas {
    final lista = <String>[];
    if (_esquemaPreferido != null) lista.add(_esquemaPreferido!);
    for (final esquema in const ['https', 'http']) {
      if (!lista.contains(esquema)) lista.add(esquema);
    }
    return lista;
  }

  Future<List<TentativaConexao>> testarConexao() async {
    await _tentarConectar();
    return _ultimasTentativas;
  }

  /// Descobre o endereço/schema do GUI. Com API key usa `/rest/system/status`;
  /// sem ela usa `/meta.js` (que pode exigir auth em algumas configurações).
  Future<bool> _tentarConectar() async {
    final tentativas = <TentativaConexao>[];
    final caminhoProbe = _apiKey != null ? '/rest/system/status' : '/meta.js';
    for (final hostTentado in <String>{host, 'localhost'}) {
      for (final portaTentada in _portas) {
        for (final esquema in _esquemas) {
          final url = '$esquema://$hostTentado:$portaTentada$caminhoProbe';
          HttpClient? cliente;
          try {
            cliente = HttpClient()..connectionTimeout = const Duration(seconds: 2);
            if (esquema == 'https') {
              cliente.badCertificateCallback = (certificado, hostRemoto, portaRemota) => true;
            }
            final requisicao = await cliente.getUrl(Uri.parse(url));
            if (_apiKey != null) {
              requisicao.headers.set('X-API-Key', _apiKey!);
            }
            final resposta = await requisicao.close().timeout(const Duration(seconds: 3));
            final corpo = await utf8.decoder.bind(resposta).join();
            if (resposta.statusCode != 200) {
              final trecho = corpo.trim().replaceAll('\n', ' ');
              final resumo = trecho.length > 180 ? trecho.substring(0, 180) : trecho;
              debugPrint('[REST] $url -> HTTP ${resposta.statusCode} $resumo');
              tentativas.add(
                TentativaConexao(
                  url: url,
                  ok: false,
                  detalhe: 'HTTP ${resposta.statusCode}${resumo.isEmpty ? '' : ': $resumo'}',
                ),
              );
              cliente.close(force: true);
              continue;
            }
            _cliente = cliente;
            _esquemaAtivo = esquema;
            _hostAtivo = hostTentado;
            _portaAtiva = portaTentada;
            debugPrint('[REST] conectado em $url');
            tentativas.add(TentativaConexao(url: url, ok: true, detalhe: 'conectado'));
            _ultimasTentativas = tentativas;
            return true;
          } catch (e) {
            final detalhe = _resumirErro(e);
            debugPrint('[REST] falhou $url -> $detalhe');
            tentativas.add(TentativaConexao(url: url, ok: false, detalhe: detalhe));
            cliente?.close(force: true);
          }
        }
      }
    }
    _ultimasTentativas = tentativas;
    return false;
  }

  /// Garante que temos como chamar o REST: API key ou token CSRF.
  Future<void> garantirAcesso() async {
    if (temApiKey) return;
    final negociou = await _obterTokenCsrf();
    if (!negociou) {
      throw const RespostaInvalida(
        'O motor respondeu, mas não foi possível negociar o acesso. '
        'Talvez a interface tenha usuário e senha sem API key disponível.',
      );
    }
  }

  String _resumirErro(Object erro) {
    if (erro is SocketException) {
      return erro.osError?.message ?? erro.message;
    }
    if (erro is TimeoutException) {
      return 'tempo esgotado';
    }
    if (erro is HandshakeException) {
      return 'falha de TLS: ${erro.message}';
    }
    if (erro is HttpException) {
      return erro.message;
    }
    return erro.toString();
  }

  /// Faz `GET /` e extrai o cookie `CSRF-Token-<unique>` que o motor emite.
  Future<bool> _obterTokenCsrf() async {
    final cliente = _cliente;
    final esquema = _esquemaAtivo;
    final hostAtivo = _hostAtivo;
    final portaAtiva = _portaAtiva;
    if (cliente == null || esquema == null || hostAtivo == null || portaAtiva == null) {
      return false;
    }

    final requisicao = await cliente.getUrl(Uri.parse('$esquema://$hostAtivo:$portaAtiva/'));
    final resposta = await requisicao.close().timeout(const Duration(seconds: 8));
    await resposta.drain<void>();

    final cookies = resposta.headers['set-cookie'] ?? const <String>[];
    for (final cookie in cookies) {
      final par = cookie.split(';').first;
      final separador = par.indexOf('=');
      if (separador <= 0) continue;
      final nome = par.substring(0, separador);
      if (nome.startsWith('CSRF-Token-')) {
        _nomeTokenCsrf = nome;
        _valorTokenCsrf = par.substring(separador + 1);
        return true;
      }
    }
    return false;
  }

  /// Espera o motor subir e deixa o endereço REST resolvido.
  Future<void> esperarDisponivel({Duration limite = const Duration(seconds: 60)}) async {
    final fim = DateTime.now().add(limite);
    while (true) {
      if (await _tentarConectar()) return;
      if (DateTime.now().isAfter(fim)) {
        throw MotorIndisponivel(
          'O motor não respondeu nas portas ${_portas.join('/')}.${_resumoFalhas()}',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }
  }

  String _resumoFalhas() {
    final detalhes = _ultimasTentativas
        .map((tentativa) => tentativa.detalhe)
        .where((detalhe) => detalhe.isNotEmpty)
        .toSet()
        .take(2)
        .join('; ');
    return detalhes.isEmpty ? '' : ' (tentativas: $detalhes)';
  }

  Future<RespostaRest> _requisicao(String metodo, String caminho, {Object? corpo}) async {
    final cliente = _cliente;
    final esquema = _esquemaAtivo;
    final hostAtivo = _hostAtivo;
    final portaAtiva = _portaAtiva;
    if (cliente == null || esquema == null || hostAtivo == null || portaAtiva == null) {
      throw const RespostaInvalida('Sem conexão com o motor.');
    }
    final requisicao = await cliente.openUrl(
      metodo,
      Uri.parse('$esquema://$hostAtivo:$portaAtiva$caminho'),
    );
    if (_apiKey != null) {
      requisicao.headers.set('X-API-Key', _apiKey!);
    } else if (_nomeTokenCsrf != null && _valorTokenCsrf != null) {
      requisicao.headers.set('Cookie', '$_nomeTokenCsrf=$_valorTokenCsrf');
      requisicao.headers.set('X-$_nomeTokenCsrf', _valorTokenCsrf!);
    }
    if (corpo != null) {
      requisicao.headers.contentType = ContentType.json;
      requisicao.write(jsonEncode(corpo));
    }
    final resposta = await requisicao.close().timeout(const Duration(seconds: 20));
    final texto = await utf8.decoder.bind(resposta).join();
    debugPrint('[REST] $metodo $caminho -> HTTP ${resposta.statusCode}');
    return RespostaRest(resposta.statusCode, texto);
  }

  /// Lê a configuração e devolve as pastas com rótulo e caminho.
  Future<List<PastaSyncthing>> listarPastas() async {
    final resposta = await _requisicao('GET', '/rest/config');
    if (!resposta.ok) {
      throw RespostaInvalida('Falha ao ler a configuração (HTTP ${resposta.codigo}).');
    }
    final json = jsonDecode(resposta.corpo) as Map<String, dynamic>;
    final bruto = (json['folders'] as List?) ?? const [];
    return bruto
        .whereType<Map<String, dynamic>>()
        .map(PastaSyncthing.doJson)
        .toList(growable: false);
  }

  /// Consulta o estado de uma pasta pelo id técnico.
  Future<Map<String, dynamic>> statusPasta(String id) async {
    final caminho = '/rest/db/status?folder=${Uri.encodeComponent(id)}';
    final resposta = await _requisicao('GET', caminho);
    if (!resposta.ok) {
      throw RespostaInvalida('Falha ao ler o estado da pasta (HTTP ${resposta.codigo}).');
    }
    return jsonDecode(resposta.corpo) as Map<String, dynamic>;
  }

  /// Força uma verificação de mudanças (todas as pastas ou apenas uma).
  Future<void> rescan([String? id]) async {
    final sufixo = id != null ? '?folder=${Uri.encodeComponent(id)}' : '';
    final resposta = await _requisicao('POST', '/rest/db/scan$sufixo');
    if (!resposta.ok) {
      throw RespostaInvalida('Falha ao solicitar verificação (HTTP ${resposta.codigo}).');
    }
  }

  // ==================== CONFIG: DISPOSITIVOS E PASTAS ====================

  Future<Map<String, dynamic>> sistemaStatus() async {
    final resposta = await _requisicao('GET', '/rest/system/status');
    if (!resposta.ok) {
      throw RespostaInvalida('Falha ao ler o status (HTTP ${resposta.codigo}).');
    }
    return jsonDecode(resposta.corpo) as Map<String, dynamic>;
  }

  Future<String?> meuDeviceId() async {
    final status = await sistemaStatus();
    return (status['myID'] ?? '').toString().isEmpty ? null : status['myID'].toString();
  }

  Future<List<DispositivoSyncthing>> listarDispositivos() async {
    final resposta = await _requisicao('GET', '/rest/config/devices');
    if (!resposta.ok) {
      throw RespostaInvalida('Falha ao ler os dispositivos (HTTP ${resposta.codigo}).');
    }
    final lista = jsonDecode(resposta.corpo) as List;
    return lista
        .whereType<Map<String, dynamic>>()
        .map(DispositivoSyncthing.doJson)
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> modeloPasta() async {
    final resposta = await _requisicao('GET', '/rest/config/defaults/folder');
    if (!resposta.ok) {
      throw RespostaInvalida('Falha ao ler o modelo de pasta (HTTP ${resposta.codigo}).');
    }
    return jsonDecode(resposta.corpo) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> modeloDispositivo() async {
    final resposta = await _requisicao('GET', '/rest/config/defaults/device');
    if (!resposta.ok) {
      throw RespostaInvalida('Falha ao ler o modelo de dispositivo (HTTP ${resposta.codigo}).');
    }
    return jsonDecode(resposta.corpo) as Map<String, dynamic>;
  }

  Future<void> criarPasta(Map<String, dynamic> pasta) async {
    final resposta = await _requisicao('POST', '/rest/config/folders', corpo: pasta);
    if (!resposta.ok) {
      throw RespostaInvalida('Falha ao criar pasta (HTTP ${resposta.codigo}): ${resposta.corpo}');
    }
  }

  Future<void> atualizarPasta(String id, Map<String, dynamic> parcial) async {
    final resposta = await _requisicao(
      'PATCH',
      '/rest/config/folders/${Uri.encodeComponent(id)}',
      corpo: parcial,
    );
    if (!resposta.ok) {
      throw RespostaInvalida('Falha ao editar pasta (HTTP ${resposta.codigo}): ${resposta.corpo}');
    }
  }

  Future<void> excluirPasta(String id) async {
    final resposta = await _requisicao(
      'DELETE',
      '/rest/config/folders/${Uri.encodeComponent(id)}',
    );
    if (!resposta.ok) {
      throw RespostaInvalida('Falha ao excluir pasta (HTTP ${resposta.codigo}).');
    }
  }

  Future<void> criarDispositivo(Map<String, dynamic> dispositivo) async {
    final resposta = await _requisicao(
      'POST',
      '/rest/config/devices',
      corpo: dispositivo,
    );
    if (!resposta.ok) {
      throw RespostaInvalida(
        'Falha ao adicionar computador (HTTP ${resposta.codigo}): ${resposta.corpo}',
      );
    }
  }

  Future<void> atualizarDispositivo(String id, Map<String, dynamic> parcial) async {
    final resposta = await _requisicao(
      'PATCH',
      '/rest/config/devices/${Uri.encodeComponent(id)}',
      corpo: parcial,
    );
    if (!resposta.ok) {
      throw RespostaInvalida('Falha ao editar computador (HTTP ${resposta.codigo}).');
    }
  }

  Future<void> excluirDispositivo(String id) async {
    final resposta = await _requisicao(
      'DELETE',
      '/rest/config/devices/${Uri.encodeComponent(id)}',
    );
    if (!resposta.ok) {
      throw RespostaInvalida('Falha ao remover computador (HTTP ${resposta.codigo}).');
    }
  }

  /// Pausa a sincronização com todos os dispositivos.
  Future<void> pausarSistema() async {
    final resposta = await _requisicao('POST', '/rest/system/pause');
    if (!resposta.ok) {
      throw RespostaInvalida('Falha ao pausar a sincronização (HTTP ${resposta.codigo}).');
    }
  }

  /// Retoma a sincronização com todos os dispositivos.
  Future<void> retomarSistema() async {
    final resposta = await _requisicao('POST', '/rest/system/resume');
    if (!resposta.ok) {
      throw RespostaInvalida('Falha ao retomar a sincronização (HTTP ${resposta.codigo}).');
    }
  }

  void fechar() {
    _cliente?.close(force: true);
    _cliente = null;
    _esquemaAtivo = null;
    _hostAtivo = null;
    _portaAtiva = null;
    _nomeTokenCsrf = null;
    _valorTokenCsrf = null;
  }
}
