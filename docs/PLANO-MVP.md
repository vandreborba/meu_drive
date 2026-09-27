# Plano — Meu Drive (MVP)

App Flutter (Android) que parece um explorador de arquivos, com o **Syncthing-Fork**
como motor de sincronização escondido. Ao abrir, acorda o motor, sincroniza e mostra
as pastas amigáveis e o estado. Também permite navegar arquivos do celular que não
são sincronizados. Se o motor não estiver instalado, oferece instalação pelo F-Droid.

Base técnica verificada em [`INTEGRACAO-SYNCTHING-FORK.md`](./INTEGRACAO-SYNCTHING-FORK.md).

## Decisões já tomadas
- Nome do app: **Meu Drive**. Pasta do projeto: `/home/vandre/Projetos/meu_drive`.
- Stack: **Flutter** (caminho `/home/vandre/flutter/bin/flutter`), **Android-only**.
- Acordar o motor: **broadcast `.action.START`** + **ativação única** guiada no
  Syncthing-Fork ("Service Control by Broadcast").
- Acesso a arquivos: **MANAGE_EXTERNAL_STORAGE** ("Todos os arquivos").
- Distribuição: **F-Droid / uso pessoal**.
- Pacotes detectados: `com.github.catfriend1.syncthingfork` (v2, F-Droid) e
  `com.github.catfriend1.syncthingandroid` (v1/Play).

## Convenções (seguindo AGENTS.md dos outros projetos)
- Nomes de variáveis/funções/classes em **português**; telas com sufixo `Screen`;
  utilitários com `_aux`.
- Estado só com **Riverpod** (`Notifier`/`NotifierProvider`), widgets
  `ConsumerWidget`/`ConsumerStatefulWidget`. Nunca Bloc/ChangeNotifier/Provider comum.
- Tema com `Theme.of(context).colorScheme` / `.textTheme`; ícones `MdiIcons`;
  diálogos via `lib/utils_geral/caixa_dialogo.dart` (`MinhaCaixaDialogo`);
  opacidade `.withValues(alpha:)`; `debugPrint` (nunca `print`).
- Textos de UI via **l10n (ARB)**, pt-BR, sem strings fixas.
- Comentários em PT-BR; seções com `// ==================== SEÇÃO ====================`.
- Nunca versionar segredos.

## Arquitetura de integração (camadas)
1. `SyncthingDetectServico` (ponte nativa) — verifica se um dos pacotes está
   instalado e devolve qual prefixo de action usar.
2. `SyncthingControlServico` (ponte nativa) — envia broadcasts
   `${pkg}.action.START|STOP|FOLLOW`.
3. `SyncthingRestServico` (Dart, `dart:io HttpClient`) —
   - tenta `https://127.0.0.1:8384` e cai para `http://...`; aceita certificado
     autoassinado (`badCertificateCallback`).
   - `esperarDisponivel()`: faz poll em `GET /meta.js` até responder (timeout ~20 s).
   - **handshake CSRF**: `GET /` captura `Set-Cookie: CSRF-Token-<unique>=<token>`;
     monta o header `X-CSRF-Token-<unique>`. Sem API key.
   - `lerConfig()` → `GET /rest/config`; `statusPasta(id)` → `GET /rest/db/status`;
     `rescan(id?)` → `POST /rest/db/scan`; `eventos(since)` → `GET /rest/events`.
4. Modelos: `PastaSyncthing(id, label, path, tipo, pausada)` e `EstadoPasta`.
5. Riverpod: `motorProvider` (instalado/estado), `pastasProvider`, `navegadorProvider`.

## Fluxo de inicialização
1. Detecta instalação. Se ausente: tela com botão **Instalar (F-Droid)**
   (`market://details?id=com.github.catfriend1.syncthingfork`, fallback para a URL
   do F-Droid).
2. Envia `.action.START` e espera `/meta.js` subir. Se não subir, mostra a **tela de
   ativação única** (passo a passo para ligar "Service Control by Broadcast") com
   "Já ativei, tentar de novo". Ao conectar, grava a flag de setup concluído.
3. Lê `/rest/config`, monta a lista de pastas amigáveis (usa `label`; fallback nome
   da pasta), dispara rescan.
4. Assina `/rest/events` para atualizar o estado em tempo real (StateChanged,
   FolderSummary, FolderCompletion).
5. UI mostra as pastas com nome amigável + badge de estado (sincronizando %,
   sincronizado, pausado, erro). Entrar na pasta abre o explorador no `path` real.

## Telas (MVP)
- `InicialScreen`: status do motor + cartões das pastas sincronizadas + atalho
  "Explorar celular".
- `ExploradorScreen` (reutilizável para pasta sincronizada e para o celular):
  navegação por diretórios reais, ícones por tipo, tamanho/data, ordenação, busca;
  abrir arquivo com app externo, compartilhar.
- `ConfiguracaoScreen`: diagnóstico, repetir ativação, porta da GUI, atalho instalar.
- `DiagnosticoScreen`: passo a passo visível (pacote detectado, `/meta.js`, CSRF,
  `/rest/config`) — essencial para validar no aparelho real.

## Android
- `applicationId` proposto: `com.vandre.meudrive` (alterável antes do release).
- Permissões: `INTERNET`, `ACCESS_NETWORK_STATE`, `MANAGE_EXTERNAL_STORAGE`,
  `ACCESS_LOCAL_NETWORK` (Android 17+).
- `<queries>` declarando os dois pacotes do Syncthing-Fork (evita QUERY_ALL_PACKAGES).
- `MainActivity.kt` com `MethodChannel` (`meu_drive/motor`): `estaInstalado()`,
  `enviarBroadcast(prefixo, acao)`, `pedirTodosArquivos()`, `temTodosArquivos()`.
- Solicitação de "Todos os arquivos" via `permission_handler`
  (`Permission.manageExternalStorage`) levando à tela do sistema quando preciso.

## Dependências propostas
`flutter_riverpod`, `http` (ou `dart:io` puro no serviço REST), `open_filex`,
`url_launcher`, `flutter_material_design_icons`, `shared_preferences`, `path`,
`path_provider`, `permission_handler`, `intl`/`flutter_localizations`.

## Estrutura de arquivos
```
lib/
  main.dart
  app.dart
  tema/theme.dart
  utils_geral/caixa_dialogo.dart
  utils_geral/formatadores_aux.dart
  l10n/  (arb pt-BR + gerados)
  dados/
    modelos/pasta_syncthing.dart
    servicos/syncthing_detect_servico.dart
    servicos/syncthing_control_servico.dart
    servicos/syncthing_rest_servico.dart
    servicos/armazenamento_servico.dart
    provedores/motor_provider.dart
    provedores/pastas_provider.dart
    provedores/navegador_provider.dart
  telas/
    inicial_screen.dart
    explorador_screen.dart
    configuracao_screen.dart
    diagnostico_screen.dart
android/app/src/main/kotlin/.../MainActivity.kt
docs/INTEGRACAO-SYNCTHING-FORK.md
docs/PLANO-MVP.md
AGENTS.md
```

## Fases
- **Fase 0 — Scaffold**: `flutter create`, tema, convenções, dependências,
  MethodChannel, manifest (permissões/`<queries>`), `AGENTS.md`.
- **Fase 1 — GO/NO-GO (spike)**: detecção de pacote, envio de START, `/meta.js`,
  handshake CSRF, leitura de `/rest/config`, tudo exposto na `DiagnosticoScreen`.
  É o teste de viabilidade em aparelho real.
- **Fase 2 — Dashboard**: `InicialScreen` com pastas amigáveis + estado via `/rest/events`.
- **Fase 3 — Explorador**: lista/navegação de arquivos, abrir/compartilhar, aba "Celular".
- **Fase 4 — Polimento**: l10n, instalação F-Droid, ícone, tratamento de erros
  (GUI com senha, porta custom, permissão negada), release.

## Validação
- `flutter analyze` e `flutter test` (testes unitários de parser CSRF, parser de
  config, formatadores).
- `flutter build apk --debug` / `--release`.
- Teste manual em aparelho real com Syncthing-Fork v2 instalado (usuário), com foco
  na Fase 1 antes de seguir.

## Riscos e mitigação
- **CSRF em localhost** é incomum → validar com a tela de diagnóstico; se falhar,
  cair para API key informada manualmente (fallback).
- **GUI com usuário/senha** → detectar HTTP 401 e orientar o usuário.
- **Porta da GUI ≠ 8384** → usar 8384 por padrão e permitir override em Configuração.
- **Broadcast desabilitado** → tela de ativação única + botão de retry.
- **Sincronização pareada com o celular errado** → fora do escopo do MVP.
