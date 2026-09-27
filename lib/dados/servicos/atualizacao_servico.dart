import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../config_app.dart';

/// Uma versão mais nova disponível no GitHub Releases.
class VersaoDisponivel {
  final String versao;
  final String urlApk;
  final String notas;

  const VersaoDisponivel({required this.versao, required this.urlApk, this.notas = ''});
}

/// Verifica e baixa atualizações publicadas no GitHub Releases.
class AtualizacaoServico {
  Future<String> versaoAtual() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// Retorna a versão mais nova (se houver) com a URL do APK.
  Future<VersaoDisponivel?> verificar() async {
    final info = await PackageInfo.fromPlatform();
    final uri = Uri.parse(
      'https://api.github.com/repos/$repositorioGitHub/releases/latest',
    );
    final resposta = await http.get(uri, headers: {'Accept': 'application/vnd.github+json'});
    if (resposta.statusCode != 200) {
      debugPrint('[Atualização] GitHub respondeu HTTP ${resposta.statusCode}');
      return null;
    }
    final json = jsonDecode(resposta.body) as Map<String, dynamic>;
    final tag = (json['tag_name'] ?? '').toString();
    final versaoNova = tag.startsWith('v') ? tag.substring(1) : tag;
    if (versaoNova.isEmpty || !_maiorQue(versaoNova, info.version)) return null;

    final assets = (json['assets'] as List?) ?? const [];
    for (final asset in assets) {
      final nome = (asset['name'] ?? '').toString().toLowerCase();
      if (nome.endsWith('.apk')) {
        final url = (asset['browser_download_url'] ?? '').toString();
        if (url.isNotEmpty) {
          return VersaoDisponivel(
            versao: versaoNova,
            urlApk: url,
            notas: (json['body'] ?? '').toString(),
          );
        }
      }
    }
    return null;
  }

  bool _maiorQue(String nova, String atual) {
    final a = _partes(nova);
    final b = _partes(atual);
    for (var i = 0; i < 3; i++) {
      if (a[i] != b[i]) return a[i] > b[i];
    }
    return false;
  }

  List<int> _partes(String versao) {
    final numeros = versao.split('.');
    return [
      for (var i = 0; i < 3; i++)
        i < numeros.length ? int.tryParse(numeros[i].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0 : 0,
    ];
  }

  /// Baixa o APK para uma pasta interna e devolve o caminho.
  Future<String> baixar(String url) async {
    final diretorio = await getApplicationSupportDirectory();
    final destino = File('${diretorio.path}/atualizacao/meu_drive.apk');
    await destino.parent.create(recursive: true);
    final resposta = await http.get(Uri.parse(url));
    await destino.writeAsBytes(resposta.bodyBytes, flush: true);
    return destino.path;
  }

  /// Abre o instalador do Android para o APK baixado.
  Future<OpenResult> instalar(String caminho) {
    return OpenFilex.open(caminho, type: 'application/vnd.android.package-archive');
  }
}
