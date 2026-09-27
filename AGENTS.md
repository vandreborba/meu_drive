# AGENTS.md

App Flutter **Meu Drive**: um explorador de arquivos amigável que usa o
**Syncthing-Fork** como motor de sincronização escondido. Ao abrir, acorda o
motor, sincroniza e mostra as pastas com nomes amigáveis e o estado. Também
permite navegar arquivos do celular que não são sincronizados.

**Plataforma: exclusivamente Android.** Não gaste esforço com iOS, desktop ou web.

## Regras de trabalho

1. **Pergunte antes de agir.** Antes de decidir ou implementar algo com mais de um
   caminho, apresente alternativas com prós/contras e confirme com o usuário.
2. **Fatos da integração são sagrados.** Toda comunicação com o Syncthing-Fork
   (broadcasts, REST, CSRF, nomes de pacote) está documentada e verificada em
   `docs/INTEGRACAO-SYNCTHING-FORK.md`. **Não invente endpoints, intents ou
   mecanismos.** Se precisar de algo novo, pesquise na fonte antes.
3. **Esconda o Syncthing.** O usuário final não deve ver conceitos como device,
   folder ID, discovery ou relay. Use os `label` das pastas como nomes amigáveis.
4. **Offline-first / privacidade.** Nada de telemetria ou analytics. Nunca
   versione segredos (keystore, `key.properties`, senhas).

## Convenções de código

- **Português:** nomes de variáveis, funções, classes e comentários em PT-BR.
- **Telas:** sufixo `Screen` (ex.: `InicialScreen`). Utilitários: sufixo `_aux`.
- **Estado:** apenas **Riverpod 3.x** (`Notifier`/`NotifierProvider`,
  `ConsumerWidget`/`ConsumerStatefulWidget`). Sem Bloc, ChangeNotifier ou Provider
  comum.
- **Tema:** `Theme.of(context).colorScheme` / `.textTheme`. Nada de `Colors.*` ou
  estilos fixos.
- **Ícones:** prefira `MdiIcons` (`flutter_material_design_icons`).
- **Diálogos/SnackBar:** sempre via `lib/utils_geral/caixa_dialogo.dart`
  (`MinhaCaixaDialogo`). Nunca `showDialog`/`ScaffoldMessenger` direto nas telas.
- **Opacidade:** use `cor.withValues(alpha: x)`; não use `withOpacity`.
- **Logs:** `debugPrint` (nunca `print`).
- **Textos de UI:** sempre via `AppLocalizations` (ARBs em `lib/l10n/`); nenhuma
  string fixa na interface. Após editar um `.arb`, rode `flutter gen-l10n`.
- **Seções:** divida arquivos grandes com
  `// ==================== NOME DA SEÇÃO ====================`.

## Arquitetura

O motor (Syncthing) é **embutido** no app e executado em um serviço próprio — já
não usamos o Syncthing-Fork em tempo de execução (ver `docs/MOTOR-EMBUTIDO.md`).

- `android/.../MotorService.kt` → foreground service que executa
  `jniLibs/<abi>/libsyncthing.so` (home = `filesDir`), com notificação e
  reinício automático.
- `android/.../MainActivity.kt` → MethodChannel `meu_drive/motor`: iniciar/parar
  o motor, importar config do Syncthing-Fork, permissões.
- `lib/dados/servicos/ponte_motor_servico.dart` → chama o canal nativo.
- `lib/dados/servicos/syncthing_rest_servico.dart` → REST em localhost **sem API
  key** (handshake CSRF) contra `127.0.0.1:8384`.
- `lib/dados/provedores/motor_provider.dart` → inicia o motor, lê as pastas e
  atualiza o estado (poll de 4 s).
- `scripts/atualizar_motor.sh` → atualiza o binário do motor.
- `docs/MOTOR-EMBUTIDO.md` → fonte da verdade do motor embutido.
- `docs/INTEGRACAO-SYNCTHING-FORK.md` → referência histórica + migração.

## Comandos

- Flutter: `/home/vandre/flutter/bin/flutter`
- Analisar: `flutter analyze`
- Testar: `flutter test`
- Build: `flutter build apk --debug` (release usa chave de debug por enquanto)
- Atualizar o motor: `scripts/atualizar_motor.sh`
- Ícone: `python3 scripts/gerar_icone.py && dart run flutter_launcher_icons`

O build Android exige um JDK com `javac`. Esta máquina usa
`/home/vandre/jdk-21`, fixado em `android/gradle.properties`
(`org.gradle.java.home`). O JDK 25 do sistema não tem compilador e quebra o build.
