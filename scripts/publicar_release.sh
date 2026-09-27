#!/usr/bin/env bash
#
# Publica uma release no GitHub com o APK de release assinado, para o
# atualizador do app encontrar.
#
# Uso: scripts/publicar_release.sh 1.1.0 "Notas da versão"
#
# Antes de rodar: ajuste o "version: X.Y.Z+N" no pubspec.yaml (o N é o versionCode).
# Requer: gh autenticado (gh auth login) e android/key.properties presente.
set -euo pipefail

VERSAO="${1:?informe a versão, ex.: 1.1.0}"
NOTAS="${2:-Meu Drive v$VERSAO}"
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER="${FLUTTER:-/home/vandre/flutter/bin/flutter}"

cd "$RAIZ"

if [ ! -f android/key.properties ]; then
  echo "ERRO: android/key.properties não encontrado (assinatura de release)." >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "ERRO: gh não está autenticado. Rode: gh auth login" >&2
  exit 1
fi

echo "Compilando APK de release..."
"$FLUTTER" build apk --release

echo "Criando release v$VERSAO..."
gh release create "v$VERSAO" build/app/outputs/flutter-apk/app-release.apk \
  --title "v$VERSAO" --notes "$NOTAS"

echo "Pronto: release v$VERSAO publicada."
