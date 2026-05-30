FROM nginx:alpine

COPY frontend/build/web /usr/share/nginx/html
COPY frontend/web/legacy.html /usr/share/nginx/html/legacy.html
COPY infra/antigravity-nginx/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
