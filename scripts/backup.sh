#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
#  backup.sh — Backup automático: Redis RDB (gzip) + docker-compose.yml
#
#  Uso manual (desde el host):
#    bash scripts/backup.sh
#
#  Uso en Docker (via entrypoint.sh del servicio backup):
#    Variables inyectadas por docker-compose:
#      BACKUP_DIR=/backups
#      COMPOSE_FILE=/repo/docker-compose.yml
#      REDIS_PASSWORD=...
#      BACKUP_KEEP_DAYS=7
#
#  Todo el output va a stdout — el driver json-file de Docker rota los logs.
# ══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

# ── Rutas — anulables por variable de entorno ─────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

BACKUP_DIR="${BACKUP_DIR:-$REPO_ROOT/backups}"
COMPOSE_FILE="${COMPOSE_FILE:-$REPO_ROOT/docker-compose.yml}"
KEEP_DAYS="${BACKUP_KEEP_DAYS:-7}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

mkdir -p "$BACKUP_DIR"

echo "[backup] ── ${TIMESTAMP} ─────────────────────────────────────────────────"

# ── 1. docker-compose.yml ─────────────────────────────────────────────────────
if [ -f "$COMPOSE_FILE" ]; then
    cp "$COMPOSE_FILE" "$BACKUP_DIR/compose_${TIMESTAMP}.yml"
    echo "[backup] compose → compose_${TIMESTAMP}.yml"
else
    echo "[backup] AVISO: $COMPOSE_FILE no encontrado, saltando"
fi

# ── 2. Redis RDB (comprimido con gzip) ────────────────────────────────────────
# Detectar el contenedor Redis del proyecto angel-ctrl
REDIS_CONTAINER=""
for FILTER in \
    "name=angel-ctrl-redis" \
    "name=angel-ctrl_redis" \
    "label=com.docker.compose.project=angel-ctrl,com.docker.compose.service=redis" \
    "label=com.docker.compose.service=redis"; do
    REDIS_CONTAINER=$(docker ps --filter "$FILTER" --format "{{.Names}}" 2>/dev/null | head -1 || true)
    [ -n "$REDIS_CONTAINER" ] && break
done

if [ -n "$REDIS_CONTAINER" ]; then
    echo "[backup] Redis: $REDIS_CONTAINER — forzando BGSAVE..."
    AUTH_FLAG=""
    [ -n "${REDIS_PASSWORD:-}" ] && AUTH_FLAG="-a $REDIS_PASSWORD --no-auth-warning"
    # shellcheck disable=SC2086
    docker exec "$REDIS_CONTAINER" \
        redis-cli $AUTH_FLAG BGSAVE > /dev/null 2>&1 || true

    # Esperar a que el BGSAVE termine (máximo 10 s)
    for _ in 1 2 3 4 5; do
        sleep 2
        # shellcheck disable=SC2086
        LAST=$(docker exec "$REDIS_CONTAINER" \
            redis-cli $AUTH_FLAG LASTSAVE 2>/dev/null || echo "0")
        [ "$LAST" -gt 0 ] && break
    done

    TMP_RDB="$BACKUP_DIR/redis_${TIMESTAMP}.rdb.tmp"
    FINAL_RDB="$BACKUP_DIR/redis_${TIMESTAMP}.rdb.gz"

    if docker cp "$REDIS_CONTAINER:/data/dump.rdb" "$TMP_RDB" 2>/dev/null; then
        gzip -c "$TMP_RDB" > "$FINAL_RDB"
        rm -f "$TMP_RDB"
        SIZE=$(du -sh "$FINAL_RDB" | cut -f1)
        echo "[backup] Redis RDB → redis_${TIMESTAMP}.rdb.gz ($SIZE)"
    else
        rm -f "$TMP_RDB"
        echo "[backup] AVISO: dump.rdb no encontrado en $REDIS_CONTAINER (Redis vacío?)"
    fi
else
    echo "[backup] AVISO: Contenedor Redis no encontrado, saltando RDB"
fi

# ── 3. Limpieza de archivos más antiguos que KEEP_DAYS ───────────────────────
find "$BACKUP_DIR" -maxdepth 1 \
    \( -name "compose_*.yml" -o -name "redis_*.rdb.gz" \) \
    -mtime "+${KEEP_DAYS}" -delete
echo "[backup] Limpieza: eliminados archivos > ${KEEP_DAYS} días"

# ── 4. Resumen ────────────────────────────────────────────────────────────────
TOTAL=$(find "$BACKUP_DIR" -maxdepth 1 -name "compose_*" -o -name "redis_*" \
    2>/dev/null | wc -l || echo "0")
DISK=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1 || echo "?")
echo "[backup] Completado — $TOTAL archivos, ${DISK} en disco"
