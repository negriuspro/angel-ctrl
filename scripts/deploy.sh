#!/bin/bash
# ══════════════════════════════════════════════════════
#  deploy.sh — Deploy manual o via GitHub Actions runner
#  Uso: bash scripts/deploy.sh
# ══════════════════════════════════════════════════════
set -euo pipefail

DEPLOY_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DEPLOY_DIR"

echo "[1/5] Actualizando codigo..."
git pull origin main

echo "[2/5] Reconstruyendo contenedores..."
docker compose up -d --build --remove-orphans

echo "[3/5] Esperando que el backend este healthy..."
RETRIES=0
until docker compose ps backend | grep -q "healthy" || [ "$RETRIES" -ge 20 ]; do
    sleep 5
    RETRIES=$((RETRIES + 1))
    echo "  ... intento $RETRIES/20"
done

if [ "$RETRIES" -ge 20 ]; then
    echo "[ERROR] Backend no alcanzo estado healthy en 100 segundos."
    docker compose logs --tail=30 backend
    exit 1
fi

echo "[4/5] Limpiando imagenes sin uso..."
docker image prune -f --filter "until=24h"

echo "[5/5] Verificando salud via nginx..."
sleep 5
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${APP_PORT:-3000}/)
if [ "$HTTP_CODE" = "200" ]; then
    echo "[OK] Deploy exitoso. App disponible en http://localhost:${APP_PORT:-3000}"
else
    echo "[ERROR] Nginx retorno HTTP $HTTP_CODE"
    docker compose logs --tail=20 nginx
    exit 1
fi
