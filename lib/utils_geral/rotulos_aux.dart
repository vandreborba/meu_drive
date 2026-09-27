import 'package:meu_drive/dados/provedores/motor_provider.dart';
import 'package:meu_drive/l10n/gerado/app_localizations.dart';

/// Rótulo amigável (e em português) para a fase atual do motor.
String rotuloFaseMotor(AppLocalizations textos, FaseMotor fase) {
  return switch (fase) {
    FaseMotor.verificando => textos.faseVerificando,
    FaseMotor.precisaPermissao => textos.fasePrecisaPermissao,
    FaseMotor.iniciando => textos.faseIniciando,
    FaseMotor.conectado => textos.faseConectado,
    FaseMotor.parado => textos.faseParado,
    FaseMotor.erro => textos.faseErro,
  };
}
