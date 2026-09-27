#!/usr/bin/env bash
#
# Atualiza o binário do motor (Syncthing) embutido no Meu Drive.
#
# O Meu Drive empacota o Syncthing em android/app/src/main/jniLibs/<abi>/libsyncthing.so.
# Este script pega o binário mais recente do APK do Syncthing-Fork no F-Droid
# (que acompanha o upstream) e recompila o APK.
#
# Uso:  scripts/atualizar_motor.sh
set -euo pipefail

PACOTE="com.github.catfriend1.syncthingfork"
ABIS=("arm64-v8a" "x86_64")
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER="${FLUTTER:-/home/vandre/flutter/bin/flutter}"

echo "Consultando a versão mais recente de $PACOTE no F-Droid..."
CODIGO="$(curl -fsSL "https://f-droid.org/api/v1/packages/$PACOTE" \
  | python3 -c 'import sys, json; print(json.load(sys.stdin)["suggestedVersionCode"])')"
echo "  suggestedVersionCode = $CODIGO"

APK_URL="https://f-droid.org/repo/${PACOTE}_${CODIGO}.apk"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Baixando $APK_URL ..."
curl -fL --progress-bar -o "$TMP/syncthing-fork.apk" "$APK_URL"

for ABI in "${ABIS[@]}"; do
  DEST="$RAIZ/android/app/src/main/jniLibs/$ABI"
  mkdir -p "$DEST"
  unzip -o -j "$TMP/syncthing-fork.apk" "lib/$ABI/libsyncthingnative.so" -d "$DEST" >/dev/null
  mv -f "$DEST/libsyncthingnative.so" "$DEST/libsyncthing.so"
  echo "  atualizado $ABI ($(stat -c%s "$DEST/libsyncthing.so") bytes)"
done

echo "Recompilando o APK do Meu Drive..."
cd "$RAIZ"
"$FLUTTER" build apk --debug

echo "Pronto: build/app/outputs/flutter-apk/app-debug.apk"
