FROM redis:7-alpine

# Entrypoint que escribe config a /tmp (tmpfs en runtime)
# Evita que la contraseña quede en docker inspect o ps aux
COPY infra/redis/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 6379

HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=5 \
    CMD sh -c 'redis-cli -a "$REDIS_PASSWORD" --no-auth-warning ping | grep -q PONG'

ENTRYPOINT ["/entrypoint.sh"]
