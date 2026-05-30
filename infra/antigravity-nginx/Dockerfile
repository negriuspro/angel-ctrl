FROM nginx:alpine

# Eliminar config default de nginx
RUN rm /etc/nginx/conf.d/default.conf

# Flutter web build (pre-compilado localmente)
COPY frontend/build/web /usr/share/nginx/html

# Config nginx optimizada
COPY infra/antigravity-nginx/nginx.conf /etc/nginx/conf.d/default.conf

# Usuario no-root para nginx
RUN chown -R nginx:nginx /usr/share/nginx/html \
    && chown -R nginx:nginx /var/cache/nginx \
    && chown -R nginx:nginx /var/log/nginx \
    && touch /var/run/nginx.pid \
    && chown nginx:nginx /var/run/nginx.pid

USER nginx

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD wget --spider -q http://127.0.0.1/ || exit 1
