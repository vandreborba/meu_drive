import 'package:flutter_test/flutter_test.dart';
import 'package:meu_drive/dados/modelos/estado_pasta.dart';
import 'package:meu_drive/dados/modelos/pasta_syncthing.dart';

PastaSyncthing _pasta({bool pausada = false}) => PastaSyncthing(
      id: 'abc',
      rotulo: 'Fotos',
      caminho: '/storage/emulated/0/Fotos',
      tipo: 'sendreceive',
      pausada: pausada,
    );

void main() {
  group('PastaSyncthing.nomeAmigavel', () {
    test('usa o rótulo quando existe', () {
      expect(_pasta().nomeAmigavel, 'Fotos');
    });

    test('cai para o nome da pasta quando o rótulo está vazio', () {
      const pasta = PastaSyncthing(
        id: 'x',
        rotulo: '',
        caminho: '/storage/emulated/0/Nossa Pasta',
        tipo: 'sendreceive',
        pausada: false,
      );
      expect(pasta.nomeAmigavel, 'Nossa Pasta');
    });
  });

  group('PastaSyncthing.expandirCaminhoSyncthing', () {
    test('expande ~/ para o armazenamento compartilhado', () {
      expect(expandirCaminho(), '/storage/emulated/0/Sync');
    });
  });

  group('EstadoPasta.doStatus', () {
    test('pausada tem prioridade', () {
      final estado = EstadoPasta.doStatus(_pasta(pausada: true), {'state': 'idle'});
      expect(estado.fase, FasePasta.pausada);
    });

    test('idle vira sincronizado', () {
      final estado = EstadoPasta.doStatus(_pasta(), {'state': 'idle'});
      expect(estado.fase, FasePasta.sincronizado);
    });

    test('syncing vira sincronizando com percentual', () {
      final estado = EstadoPasta.doStatus(_pasta(), {
        'state': 'syncing',
        'globalBytes': 100,
        'inSyncBytes': 40,
      });
      expect(estado.fase, FasePasta.sincronizando);
      expect(estado.percentual, 40);
    });

    test('error vira erro', () {
      final estado = EstadoPasta.doStatus(_pasta(), {'state': 'error', 'error': 'falhou'});
      expect(estado.fase, FasePasta.erro);
    });
  });
}

String expandirCaminho() {
  return PastaSyncthing.expandirCaminhoSyncthing('~/Sync');
}
