/// Utilitários de formatação usados pela interface (tamanho, data e hora).
library;

String formatarBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const unidades = ['KB', 'MB', 'GB', 'TB'];
  var valor = bytes / 1024;
  var indice = 0;
  while (valor >= 1024 && indice < unidades.length - 1) {
    valor /= 1024;
    indice++;
  }
  final casas = valor >= 10 ? 0 : 1;
  return '${valor.toStringAsFixed(casas)} ${unidades[indice]}';
}

String formatarData(DateTime data) {
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');
  return '$dia/$mes/${data.year}';
}

String formatarHora(DateTime data) {
  final hora = data.hour.toString().padLeft(2, '0');
  final minuto = data.minute.toString().padLeft(2, '0');
  final segundo = data.second.toString().padLeft(2, '0');
  return '$hora:$minuto:$segundo';
}

String formatarDataHora(DateTime data) => '${formatarData(data)} ${formatarHora(data)}';
