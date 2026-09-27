# Integração com o Syncthing-Fork — fatos verificados

> **SUPERSEDIDO.** O Meu Drive passou a **embutir o motor Syncthing** e não
> controla mais o Syncthing-Fork (o broadcast de `START` é bloqueado pelo Android
> 12+). Este documento fica como referência histórica e para a **migração** da
> configuração (ver `docs/MOTOR-EMBUTIDO.md`).

> Documento de apoio do projeto **Meu Drive**. Tudo aqui foi conferido nas fontes
> oficiais (código-fonte, docs do Syncthing e F-Droid) em 2026-09-27. Não inventar
> endpoints/intents: se for integrar, usar exatamente o que está abaixo.

## 1. Qual app usar e como detectar

O app oficial `syncthing/syncthing-android` foi **descontinuado** (última release
1.28.1, dez/2024). O substituto atual é o **Syncthing-Fork**.

| Item | Valor |
|---|---|
| Repositório atual | https://github.com/researchxxl/syncthing-android (ex-Catfriend1) |
| Pacote F-Droid (v2.x) | `com.github.catfriend1.syncthingfork` |
| Pacote Google Play (nel0x) / v1.x | `com.github.catfriend1.syncthingandroid` |
| Versão F-Droid observada | 2.1.3.0 |
| Link F-Droid | https://f-droid.org/packages/com.github.catfriend1.syncthingfork/ |
| Link market (intent) | `market://details?id=com.github.catfriend1.syncthingfork` |

**Importante:** o nome do pacote entra no nome das actions de broadcast
(`${applicationId}.action.START`). Tanto o pacote quanto as actions mudaram de
`...syncthingandroid` (v1) para `...syncthingfork` (v2). O Meu Drive deve detectar
**os dois** pacotes e usar o prefixo correspondente ao instalado.

## 2. Como "acordar" o Syncthing (iniciar o serviço)

Receptor exportado: `AppConfigReceiver`
(`app/src/main/AndroidManifest.xml`).

Actions (broadcast, `-p <package>`):
- `${applicationId}.action.START`  → força iniciar (força o serviço a rodar,
  ignorando run conditions). É exatamente o que resolve o "Syncthing fecha sozinho".
- `${applicationId}.action.STOP`   → força parar.
- `${applicationId}.action.FOLLOW` → volta a seguir as run conditions.

Envio via `adb` (equivalente ao que o app fará por Intent):
```bash
adb shell am broadcast -a com.github.catfriend1.syncthingfork.action.START \
  -p com.github.catfriend1.syncthingfork
```

**Trava obrigatória:** o receptor só age se a preferência
`PREF_BROADCAST_SERVICE_CONTROL` (`broadcast_service_control`) estiver ligada.
Caso contrário ele **ignora** silenciosamente (log: "Enable Settings >
Experimental > Service Control by Broadcast"). Ou seja, é necessário um
**ajuste único** no Syncthing-Fork em Settings (o app loga como "Experimental",
a wiki chama de "Behaviour"). Não há como ligar isso programaticamente
(preferência privada do outro app) nem deep-link para a tela (SettingsActivity
não é exportada).

Consequência de projeto: o Meu Drive precisa de um **passo de ativação único**
guiado; depois disso pode iniciar/parar o motor sozinho para sempre.

## 3. Como ler pastas e estado de sincronização (sem API key)

O REST do Syncthing exige o header `X-API-Key`, e a API key fica em
`<gui><apikey>` do `config.xml` — que no Android é **armazenamento privado** do
Syncthing-Fork (`context.getFilesDir()/config.xml`, i.e.
`/data/data/<pkg>/files/config.xml`). O Meu Drive **não consegue ler** esse arquivo.

Rota correta e documentada, **sem precisar de API key**: o mecanismo CSRF da GUI,
usado pelo próprio painel web.

Fonte: `syncthing/syncthing` → `lib/api/api_csrf.go` e docs
"HTTP Utility Services API".

Fluxo:
1. `GET http(s)://127.0.0.1:8384/` → a resposta traz
   `Set-Cookie: CSRF-Token-<unique>=<token>`.
2. Em cada chamada `/rest/...` enviar:
   - header `X-CSRF-Token-<unique>: <token>`
   - (o valor do cookie é um token válido no store do servidor)
3. Nesse modo o servidor dispensa a API key. Requisições com API key válida
   também passam; `/rest/debug` e `/rest/noauth/...` não exigem CSRF.

Observações:
- O `<unique>` sai do **nome** do cookie; o `<token>` sai do **valor**.
- O servidor exige `Host` de localhost (só bypass com `insecureSkipHostcheck`).
- O Syncthing-Fork usa **HTTPS com certificado autoassinado** no Android 7.1+
  (fallback HTTP só em versões sem TLS 1.2). O cliente precisa aceitar o cert
  inválido.
- Porta padrão da GUI: **8384** (`Constants.DEFAULT_WEBGUI_TCP_PORT`). Se o
  usuário trocar a porta, não há como descobrir sem config → tratar como caso
  não suportado na v1.
- Detecção barata de "está acordado?" sem auth: `GET /meta.js`
  (serviço público, não exige API key): retorna `var metadata = {"deviceID":"..."}`.
- Se o usuário tiver definido **usuário/senha** na GUI, o REST também exige
  autenticação básica → CSRF sozinho não basta (caso a tratar/avisar).

### Endpoints úteis (Syncthing v2.x)
- `GET /rest/config` — config completa: pastas (`id`, `label`, `path`, `type`,
  `paused`, devices), gui, options. **Fonte dos nomes amigáveis (`label`)**.
- `GET /rest/db/status?folder=<id>` — estado da pasta (`state`, `stateChanged`,
  `errors`, `needBytes`, etc.).
- `GET /rest/db/completion?folder=<id>&device=<id>` — % concluído.
- `GET /rest/events?since=<n>` — stream (long-poll) de eventos:
  `StateChanged`, `FolderSummary`, `FolderCompletion`, `ItemFinished`.
- `POST /rest/db/scan?folder=<id>` — força rescan (sem `folder`, todas).
- `GET /rest/system/status`, `GET /rest/system/connections`, `GET /rest/version`.

## 4. Broadcast de saída do Syncthing → app externo: NÃO utilizável

Existe `ACTION_NOTIFY_FOLDER_SYNC_COMPLETE` (extras `deviceId`, `folderId`,
`folderLabel`, `folderPath`, `folderState`), protegido pela permission
`${applicationId}.permission.RECEIVE_SYNC_STATUS` (normal). **Porém** em
`RestApi.sendBroadcastToApps` ele só é enviado para uma lista **fixa e codificada**
de pacotes: atualmente apenas `org.decsync.cc`. Logo, o Meu Drive **não recebe**
esse broadcast. Não contar com ele; usar o REST/eventos.

## 5. Outros fatos / armadilhas

- `MainActivity` **não é exportada**; a action `${applicationId}.MainActivity.EXIT`
  não serve para controle externo.
- `SyncthingService` também não é exportada (não dá para `startService` direto).
- A instância só vira `ACTIVE` quando o wrapper termina de ler a config via REST;
  ao acordar, espere o Web GUI subir (poll em `/meta.js`) antes de consultar REST.
- Android 17+ passa a exigir a permissão de runtime `ACCESS_LOCAL_NETWORK` para
  tráfego de rede local (o próprio Syncthing-Fork declara isso no manifest).
  O Meu Drive deve declarar/solicitar quando aplicável.
- Porta de dados (sync P2P) padrão: 22000; GUI: 8384.
- A pasta de sincronização típica fica em armazenamento compartilhado
  (`/storage/emulated/0/...`), então o Meu Drive consegue listar os arquivos.
  O `path` no config pode vir com `~/` → o wrapper expande para o caminho
  absoluto (ver `RestApi.getFolders`).

## 6. Fontes
- https://github.com/researchxxl/syncthing-android (README, AndroidManifest.xml,
  AppConfigReceiver.java, SyncthingService.java, RestApi.java, Constants.java)
- https://f-droid.org/packages/com.github.catfriend1.syncthingfork/
- https://docs.syncthing.net/dev/rest (REST API / API key)
- https://docs.syncthing.net/dev/http-services.html (GET /meta.js)
- https://raw.githubusercontent.com/syncthing/syncthing/main/lib/api/api_csrf.go
  (mecanismo CSRF, `X-CSRF-Token-<unique>`)
- Wiki do fork: `wiki/tips-and-tricks/Remote-Control-by-Broadcast-Intents.md`
- Fórum Syncthing: tópicos 25271 e 24860 (mudança de pacote/actions na v2.x)
