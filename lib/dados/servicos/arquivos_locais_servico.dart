import 'dart:async';
import 'dart:io';

import '../modelos/item_arquivo.dart';

/// Varre o armazenamento do aparelho para busca e últimos arquivos.
///
/// Não há índice persistente: a varredura é feita no sistema de arquivos local
/// (offline-first, sem depender do motor de sincronização).
class ArquivosLocaisServico {
  /// Raiz do armazenamento compartilhado do Android.
  static const String raizPadrao = '/storage/emulated/0';

  /// Profundidade máxima da varredura (evita árvores muito profundas).
  static const int profundidadeMaximaPadrao = 12;

  /// Nº máximo de entradas examinadas numa varredura (proteção de desempenho).
  static const int _maxEntradas = 60000;

  /// Procura arquivos cujo nome contenha [consulta], emitindo conforme acha.
  Stream<ItemArquivo> buscar(
    String consulta, {
    String raiz = raizPadrao,
    int maxResultados = 200,
    int profundidadeMaxima = profundidadeMaximaPadrao,
  }) async* {
    final alvo = consulta.trim().toLowerCase();
    if (alvo.isEmpty) return;
    var encontrados = 0;
    await for (final item in _varrer(raiz, profundidadeMaxima)) {
      if (!item.nome.toLowerCase().contains(alvo)) continue;
      yield item;
      if (++encontrados >= maxResultados) return;
    }
  }

  /// Arquivos modificados mais recentemente, do mais novo para o mais antigo.
  Future<List<ItemArquivo>> recentes({
    String raiz = raizPadrao,
    int limite = 200,
    int profundidadeMaxima = profundidadeMaximaPadrao,
    int dias = 90,
  }) async {
    final corte = dias > 0
        ? DateTime.now().subtract(Duration(days: dias))
        : null;
    final lista = <ItemArquivo>[];
    await for (final item in _varrer(raiz, profundidadeMaxima)) {
      final modificado = item.modificado;
      if (modificado == null) continue;
      if (corte != null && modificado.isBefore(corte)) continue;
      lista.add(item);
      // Mantém só os mais recentes, evitando materializar a árvore inteira.
      if (lista.length > limite * 2) {
        lista.sort(_maisRecentePrimeiro);
        lista.removeRange(limite, lista.length);
      }
    }
    lista.sort(_maisRecentePrimeiro);
    return lista.length > limite ? lista.sublist(0, limite) : lista;
  }

  static int _maisRecentePrimeiro(ItemArquivo a, ItemArquivo b) =>
      b.modificado!.compareTo(a.modificado!);

  /// Percorre [raiz] recursivamente, emitindo apenas arquivos.
  ///
  /// Ignora pastas ocultas, `Android/data` e `Android/obb` (inacessíveis ou
  /// ruído) e tolera erros de acesso item a item.
  Stream<ItemArquivo> _varrer(String raiz, int profundidadeMaxima) async* {
    var examinadas = 0;
    final pendentes = <_Pasta>[_Pasta(raiz, 0)];
    final pastaAndroid = '$raiz/Android';
    while (pendentes.isNotEmpty) {
      final atual = pendentes.removeLast();
      if (atual.profundidade >= profundidadeMaxima) continue;
      Stream<FileSystemEntity> fluxo;
      try {
        fluxo = Directory(atual.caminho).list(followLinks: false);
      } catch (_) {
        continue;
      }
      await for (final entrada in fluxo.handleError((Object _) {})) {
        if (++examinadas > _maxEntradas) return;
        final nome = ItemArquivo.nomeDe(entrada.path);
        if (nome.isEmpty || nome.startsWith('.')) continue;
        if (entrada is Directory) {
          if (atual.caminho == pastaAndroid &&
              (nome == 'data' || nome == 'obb')) {
            continue;
          }
          pendentes.add(_Pasta(entrada.path, atual.profundidade + 1));
        } else if (entrada is File) {
          try {
            final info = await entrada.stat();
            yield ItemArquivo(
              nome: nome,
              caminho: entrada.path,
              ehDiretorio: false,
              tamanho: info.size,
              modificado: info.modified,
            );
          } catch (_) {
            // Arquivo inacessível: ignora.
          }
        }
      }
    }
  }
}

class _Pasta {
  final String caminho;
  final int profundidade;

  const _Pasta(this.caminho, this.profundidade);
}
