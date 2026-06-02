#!/bin/sh
# ── Backup service entrypoint ─────────────────────────────────────────────────
# Ejecuta backup.sh cada BACKUP_INTERVAL_SECONDS segundos (default: 6 h).
# Todo el output va a stdout → el driver json-file de Docker lo rota.
set -e

INTERVAL="${BACKUP_INTERVAL_SECONDS:-21600}"

echo "[backup-svc] Iniciando. Primer backup en 60 segundos."
echo "[backup-svc] Intervalo: ${INTERVAL}s  |  Destino: ${BACKUP_DIR:-/backups}"

sleep 60

while true; do
    echo "[backup-svc] ── Ejecutando backup $(date '+%Y-%m-%d %H:%M:%S') ──"
    if bash /scripts/backup.sh; then
        # Guardar timestamp del último backup exitoso (usado por healthcheck)
        date +%s > /tmp/backup.lastrun
        echo "[backup-svc] Backup exitoso."
    else
        echo "[backup-svc] ERROR en backup (continuará en próximo ciclo)"
    fi
    echo "[backup-svc] Próximo backup: $(date -d "+${INTERVAL} seconds" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date '+%Y-%m-%d %H:%M:%S')"
    sleep "$INTERVAL"
done
