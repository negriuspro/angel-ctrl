#!/bin/bash
# deploy.sh — Script de deploy manual (alternativa al runner automático)
# Uso: bash deploy.sh
# También lo ejecuta el GitHub Actions runner automáticamente.

set -e

DEPLOY_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "[deploy] Actualizando código..."
cd "$DEPLOY_DIR"
git pull origin main

echo "[deploy] Reconstruyendo contenedores..."
docker compose up -d --build --remove-orphans

echo "[deploy] Limpiando imágenes sin uso..."
docker image prune -f

echo "[deploy] Verificando salud del backend..."
sleep 10
if curl -sf http://localhost:8080/health > /dev/null; then
  echo "[deploy] OK — stack levantado correctamente."
else
  echo "[deploy] ERROR — backend no responde. Revisa: docker compose logs antigravity-backend"
  exit 1
fi
