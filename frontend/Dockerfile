FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

COPY . .
RUN flutter pub get
RUN flutter build web --release

FROM nginx:1.27-alpine AS runtime
RUN apk add --no-cache curl
COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY web/legacy.html /usr/share/nginx/html/legacy.html
EXPOSE 80
