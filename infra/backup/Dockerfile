FROM alpine:3.20

# Instalar herramientas en tiempo de BUILD, no de runtime
# docker-cli: para BGSAVE + docker cp
# bash: requerido por backup.sh
# findutils + coreutils: find, date, wc con opciones GNU
# gzip: compresión de backups futuros
RUN apk add --no-cache \
    bash \
    docker-cli \
    findutils \
    coreutils \
    gzip \
    && rm -rf /var/cache/apk/*

COPY infra/backup/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
