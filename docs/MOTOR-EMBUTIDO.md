# Motor embutido (Syncthing dentro do Meu Drive)

> A partir desta versão, o Meu Drive **não depende mais do Syncthing-Fork**. Ele
> embute o binário oficial do Syncthing e o executa num serviço em primeiro plano
> próprio. Isso resolve o problema de "acordar" o motor: como quem inicia o
> serviço é o próprio app (em primeiro plano), a restrição do Android 12+ de
> iniciar foreground service a partir do background deixa de valer.

## Por que não usar mais o Syncthing-Fork

O receptor de broadcast do Syncthing-Fork (`AppConfigReceiver`) chama
`startForegroundService(...)` ao receber `START`. O Android 12+ proíbe iniciar um
foreground service a partir do background (com poucas exceções, e um broadcast de
terceiro não é uma delas), então o motor não subia. Não era configuração do
usuário.

## Como o motor é executado

- Binário: `android/app/src/main/jniLibs/<abi>/libsyncthing.so`
  (ABIs: `arm64-v8a`, `x86_64`).
- Precisa de `android:extractNativeLibs="true"` e
  `packaging { jniLibs { useLegacyPackaging = true } }` para o `.so` ser extraído
  em `nativeLibraryDir`. O Android/SELinux **bloqueia executar de `filesDir`**;
  executar de `nativeLibraryDir` funciona.
- Serviço: `android/app/src/main/kotlin/com/vandreapps/meu_drive/MotorService.kt`
  (foreground service `specialUse`, com notificação "Sincronizando em segundo
  plano"). Se o processo sair sozinho, o serviço reinicia (resolve o "fecha
  sozinho").
- Comando: `libsyncthing.so serve --no-browser`, com ambiente:
  - `STHOMEDIR` = `filesDir` (config + chaves + banco) — mesmo layout do
    Syncthing-Fork, o que facilita importar a configuração existente.
  - `HOME`, `STNOUPGRADE=1`, `STMONITORED=1`, `STVERSIONEXTRA=Meu Drive`,
    `SQLITE_TMPDIR`, `GOGC=100`, `FALLBACK_NET_GATEWAY_IPV4`.
- `MulticastLock` (permissão `CHANGE_WIFI_MULTICAST_STATE`) é adquirido enquanto
  roda: Android 11+ bloqueia a descoberta local sem ele.
- O endereço do GUI **não é fixo**: o Syncthing-Fork pode gravar uma porta
  aleatória (ex.: `127.0.0.1:41231`). O app lê do `config.xml` o `<address>`, o
  `tls` e a `<apikey>` e fala REST nesse endereço com o header `X-API-Key` — o
  que funciona mesmo com a GUI protegida por senha (o Syncthing-Fork define a
  senha da GUI como o hash da API key).
- Como o `/meta.js` pode responder **403** nessa configuração, a sondagem de
  prontidão usa **`/rest/system/status`** com a API key. Sem API key disponível,
  cai para `/meta.js` + handshake CSRF (`GET /` → cookie `CSRF-Token-<unique>` +
  header `X-CSRF-Token-<unique>`). Portas 8384/8385 ficam como fallback.

## Migração da configuração (mesmo device ID)

O device ID é derivado de `cert.pem`/`key.pem`. Para o PC continuar vendo o
mesmo dispositivo (sem re-parear), importamos a configuração exportada:

1. No **Syncthing-Fork**, faça *Settings → Export* (gera
   `/storage/emulated/0/backups/syncthing/config.zip`).
2. No **Meu Drive**, a importação acontece automaticamente na primeira execução
   (quando ainda não existe `config.xml`), ou manualmente em
   **Configuração → Importar do Syncthing-Fork** (substitui a config atual).
3. Depois, **não rode os dois ao mesmo tempo**: dois Syncthing com a mesma
   identidade/pastas brigam. Pare/desinstale o Syncthing-Fork.

## Gerenciamento (pastas e computadores)

A tela **Gerenciar** (abas Pastas e Computadores) usa os endpoints de config do
REST (verificados na doc v2, sem inventar nada):

- `POST /rest/config/folders` (criar), `PATCH/DELETE /rest/config/folders/{id}`.
- `POST /rest/config/devices`, `PATCH/DELETE /rest/config/devices/{id}`.
- `GET /rest/config/defaults/folder` e `/rest/config/defaults/device` (modelos).
- `GET /rest/system/status` → `myID` (Meu ID, mostrado com QR para parear).
- Compartilhar uma pasta = incluir o device na lista `devices` dela (PATCH
  substitui o array).

O seletor de pasta é o nosso próprio explorador (caminho real); o seletor SAF do
Android não serve porque o Syncthing precisa de caminho de arquivo.

## Atualizar o motor

O Android não deixa o Syncthing se auto-atualizar (o binário mora no APK), então
a versão é fixada. Para atualizar:

```bash
scripts/atualizar_motor.sh
```

O script baixa o APK mais recente do Syncthing-Fork no F-Droid (que acompanha o
upstream), extrai `libsyncthingnative.so`, renomeia para `libsyncthing.so` nos
`jniLibs` e recompila o APK.

## Limites conhecidos

- Dois motores (Syncthing-Fork + Meu Drive) não podem rodar juntos com a mesma
  identidade/pastas.
- APK maior (os binários somam ~52 MB em arm64 + x86_64).
- Doze/bateria: o serviço é foreground, mas vale deixar o app fora da
  otimização de bateria em aparelhos agressivos.
