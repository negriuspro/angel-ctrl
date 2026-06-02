#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
#  rollback.sh — Revierte a un commit anterior y reconstruye contenedores.
#
#  Uso manual (interactivo):
#    bash scripts/rollback.sh                   # HEAD~1
#    bash scripts/rollback.sh abc1234           # commit específico
#
#  Uso en CI/CD (sin prompt):
#    bash scripts/rollback.sh --force abc1234
#    bash scripts/rollback.sh --force           # HEAD~1
# ══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$ROOT_DIR"

# ── Parsear argumentos ────────────────────────────────────────────────────────
FORCE=false
TARGET_COMMIT="HEAD~1"

for ARG in "$@"; do
    case "$ARG" in
        --force|-f)  FORCE=true ;;
        --*)         echo "[rollback] Opción desconocida: $ARG" && exit 1 ;;
        *)           TARGET_COMMIT="$ARG" ;;
    esac
done

CURRENT_COMMIT="$(git rev-parse --short HEAD)"
CURRENT_MSG="$(git log -1 --format='%s')"
TARGET_FULL="$(git rev-parse "$TARGET_COMMIT" 2>/dev/null || echo "$TARGET_COMMIT")"
TARGET_SHORT="$(git rev-parse --short "$TARGET_FULL" 2>/dev/null || echo "$TARGET_FULL")"
TARGET_MSG="$(git log -1 --format='%s' "$TARGET_FULL" 2>/dev/null || echo '?')"

echo "[rollback] ──────────────────────────────────────────────────────────────"
echo "[rollback] Commit actual  : $CURRENT_COMMIT  $CURRENT_MSG"
echo "[rollback] Objetivo       : $TARGET_SHORT  $TARGET_MSG"
echo ""

if [ "$FORCE" = false ]; then
    read -rp "[rollback] ¿Confirmar rollback? [s/N] " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[sS]$ ]]; then
        echo "[rollback] Cancelado."
        exit 0
    fi
fi

# ── Backup previo al rollback ─────────────────────────────────────────────────
echo "[rollback] Ejecutando backup pre-rollback..."
bash "$SCRIPT_DIR/backup.sh" || echo "[rollback] AVISO: backup falló, continuando rollback"

# ── Revertir código ───────────────────────────────────────────────────────────
echo "[rollback] git reset --hard $TARGET_FULL"
git reset --hard "$TARGET_FULL"
echo "[rollback] Código revertido a: $(git rev-parse --short HEAD)  $(git log -1 --format='%s')"

# ── Reconstruir contenedores ──────────────────────────────────────────────────
echo "[rollback] Reconstruyendo contenedores..."
docker compose up -d --build --remove-orphans

# ── Esperar que el backend sea healthy ────────────────────────────────────────
echo "[rollback] Esperando que el backend alcance estado healthy..."
RETRIES=0
MAX_RETRIES=24  # 2 minutos

until docker compose ps backend | grep -q "healthy" || [ "$RETRIES" -ge "$MAX_RETRIES" ]; do
    sleep 5
    RETRIES=$((RETRIES + 1))
    echo "  intento $RETRIES/$MAX_RETRIES"
done

if [ "$RETRIES" -ge "$MAX_RETRIES" ]; then
    echo "[rollback] ERROR: backend no alcanzó healthy"
    docker compose logs --tail=40 backend
    exit 1
fi

echo "[rollback] ── Rollback completado ──────────────────────────────────────"
docker compose ps
