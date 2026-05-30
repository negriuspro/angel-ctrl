#!/bin/bash
# build-frontend.sh — Compila Flutter web y deja el build listo para commitear.
# Ejecutar desde la PC principal antes de hacer git push.
# Requiere Flutter instalado localmente.
# Uso: bash scripts/build-frontend.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
FRONTEND_DIR="$ROOT_DIR/frontend"

echo "[build] Compilando Flutter web..."
cd "$FRONTEND_DIR"
flutter pub get
flutter build web --release --web-renderer canvaskit

echo "[build] Build completado en frontend/build/web/"
echo "[build] Ahora puedes: git add frontend/build/web && git commit && git push"
