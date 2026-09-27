import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:meu_drive/l10n/gerado/app_localizations.dart';

/// Lê um QR code e devolve o texto lido (ex.: um Device ID).
class EscanearQrScreen extends StatefulWidget {
  const EscanearQrScreen({super.key});

  @override
  State<EscanearQrScreen> createState() => _EscanearQrScreenState();
}

class _EscanearQrScreenState extends State<EscanearQrScreen> {
  bool _lido = false;

  @override
  Widget build(BuildContext context) {
    final textos = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(textos.escanearQr)),
      body: MobileScanner(
        onDetect: (capture) {
          if (_lido) return;
          final codigo = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
          if (codigo == null || codigo.isEmpty) return;
          _lido = true;
          Navigator.of(context).pop(codigo);
        },
      ),
    );
  }
}
