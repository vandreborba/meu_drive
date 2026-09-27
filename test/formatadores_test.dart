import 'package:flutter_test/flutter_test.dart';
import 'package:meu_drive/utils_geral/formatadores_aux.dart';

void main() {
  group('formatarBytes', () {
    test('mostra bytes para valores pequenos', () {
      expect(formatarBytes(512), '512 B');
    });

    test('converte para KB e MB', () {
      expect(formatarBytes(2048), '2.0 KB');
      expect(formatarBytes(1024 * 1024 * 3), '3.0 MB');
    });
  });

  group('formatarData e formatarHora', () {
    test('preenche com zeros a esquerda', () {
      final data = DateTime(2026, 9, 7, 8, 5, 3);
      expect(formatarData(data), '07/09/2026');
      expect(formatarHora(data), '08:05:03');
    });
  });
}
