import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meu_drive/dados/provedores/tema_provider.dart';
import 'package:meu_drive/l10n/gerado/app_localizations.dart';
import 'package:meu_drive/telas/inicial_screen.dart';
import 'package:meu_drive/tema/theme.dart';

class MeuDriveApp extends ConsumerWidget {
  const MeuDriveApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modoTema = ref.watch(temaProvider);
    return MaterialApp(
      // Sem a faixa "DEBUG" no canto (indiferente no release).
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (contexto) => AppLocalizations.of(contexto).appNome,
      theme: MeuDriveTema.claro(),
      darkTheme: MeuDriveTema.escuro(),
      themeMode: modoTema,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const InicialScreen(),
    );
  }
}
