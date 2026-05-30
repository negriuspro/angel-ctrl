#!/bin/bash
# ══════════════════════════════════════════════════════════
#  update.sh — Actualización rápida sin rebuild completo
#  Uso: bash scripts/update.sh
#  Solo hace git pull + restart. Usa cuando no cambiaste
#  dependencias ni el Dockerfile.
# ══════════════════════════════════════════════════════════
set -euo pipefail

DEPLOY_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DEPLOY_DIR"

echo "[1/4] Actualizando código..."
git pull origin master || git pull origin main

echo "[2/4] Reiniciando servicios (sin rebuild)..."
docker compose up -d --remove-orphans

echo "[3/4] Esperando que el backend esté healthy..."
RETRIES=0
until docker compose ps backend | grep -q "healthy" || [ "$RETRIES" -ge 20 ]; do
    sleep 5
    RETRIES=$((RETRIES + 1))
    echo "  ... intento $RETRIES/20"
done

if [ "$RETRIES" -ge 20 ]; then
    echo "[ERROR] Backend no alcanzó estado healthy."
    docker compose logs --tail=30 backend
    exit 1
fi

echo "[4/4] Limpiando imágenes viejas..."
docker image prune -f --filter "until=24h"

echo "[OK] Actualización completada."
