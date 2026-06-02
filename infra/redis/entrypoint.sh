#!/bin/sh
# ── Redis entrypoint ──────────────────────────────────────────────────────────
# Escribe la config (incluyendo la contraseña) a /tmp (tmpfs).
# De esta forma "docker inspect" y "ps aux" muestran:
#   redis-server /tmp/redis.conf
# ... y NO la contraseña en texto plano.
set -e

: "${REDIS_PASSWORD:?REDIS_PASSWORD no definido}"

cat > /tmp/redis.conf << CONF
# Generado en runtime — NO modificar manualmente
requirepass ${REDIS_PASSWORD}
protected-mode yes

# Persistencia: RDB + AOF
appendonly yes
appendfsync everysec
save 900 1
save 300 10
dir /data

# Memoria
maxmemory 64mb
maxmemory-policy allkeys-lru

# Logging mínimo (va al driver Docker)
loglevel warning
logfile ""
CONF

chmod 600 /tmp/redis.conf
exec redis-server /tmp/redis.conf
