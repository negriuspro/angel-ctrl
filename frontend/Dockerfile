# syntax=docker/dockerfile:1

# ── Stage 1: Flutter web build (capas en orden óptimo para cache) ─────────
FROM ghcr.io/cirruslabs/flutter:3.32.0 AS builder

WORKDIR /app

# 1. Copiar solo manifiestos de dependencias (cambian poco)
#    → flutter pub get se cachea hasta que cambien pubspec.yaml / pubspec.lock
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get --no-example

# 2. Copiar código fuente (cambia frecuentemente)
COPY . .

# 3. Compilar (solo se re-ejecuta si cambió el código o los deps)
RUN flutter build web --release

# ── Stage 2: nginx runtime ────────────────────────────────────────────────
FROM nginx:1.27-alpine AS runtime

RUN apk add --no-cache curl

COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY web/legacy.html /usr/share/nginx/html/legacy.html

RUN chown -R nginx:nginx /usr/share/nginx/html

EXPOSE 80
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3   CMD curl -sf http://127.0.0.1/ >/dev/null || exit 1
