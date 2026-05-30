# Auditoría Técnica: Antigravity Control Center (interfazdocker)

**Fecha:** 28 de mayo de 2026
**Auditor:** Claude Code (revisión automatizada + análisis arquitectónico)
**Estado:** Producción activa

---

## 1. Resumen Ejecutivo

Antigravity Control Center es un panel de control auto-hospedado para administrar infraestructura Docker, monitorear contenedores y visualizar métricas de agentes AI. Corre sobre WSL2 Ubuntu en Windows 11 con Docker Desktop, y se accede vía navegador (LAN, Tailscale o localtunnel).

**Stack principal:** Flutter Web → Nginx → FastAPI (Python 3.12) → Docker SDK → Docker Engine  
**Estado actual:** 6 contenedores en producción activa, ~245 MB RAM total, todos healthy  
**Madurez:** Funcional en su capa de infraestructura; capa AI con providers stub; automations placeholder

---

## 2. Arquitectura del Sistema

### 2.1 Topología Actual (6 contenedores)

```
                    ┌─────────────────────────────┐
                    │     Tablet / Navegador       │
                    │  (LAN / Tailscale / Tunnel)  │
                    └──────────┬──────────────────┘
                               │
             ┌─────────────────┼────────────────────┐
             ▼                 ▼                    ▼
    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
    │antigravity   │  │mobile        │  │jarvis        │
    │-core:3000    │  │-core:3001    │  │-core:3002    │
    │              │  │              │  │              │
    │ nginx (80)   │  │ nginx (80)   │  │ nginx (80)   │
    │ FastAPI (8080)│  │ hub backend  │  │ py backend   │
    │ Flutter Web  │  │ Flutter Web  │  │ client web   │
    └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
           │                  │                  │
           ▼                  ▼                  ▼
    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
    │antigravity   │  │mobile        │  │jarvis        │
    │-redis        │  │-redis        │  │-redis        │
    └──────────────┘  └──────────────┘  └──────────────┘
```

### 2.2 Stack Tecnológico

| Capa | Tecnología | Versión |
|---|---|---|
| Frontend SPA | Flutter Web (Dart) | SDK >=3.5.0 |
| Frontend legacy | HTML + JS vanilla | — |
| Backend API | Python FastAPI | 0.115.6 |
| ASGI Server | Uvicorn | 0.32.1 |
| Docker SDK | docker-py | 7.1.0 |
| Reverse Proxy | Nginx | 1.27 (alpine/slim) |
| Cache/Pub-sub | Redis | 7 (AOF) |
| Serialización | Orjson + Pydantic | 2.10 / 3.10 |
| Orquestación | Docker Compose | v3 |
| SO Anfitrión | Ubuntu 24.04 (WSL2) | — |
| SO Host | Windows 11 | — |

### 2.3 Evolución Arquitectónica

**Fase 1 (original):** 12 contenedores separados (nginx, frontend, backend, redis × 3 proyectos)  
**Fase 2 (actual):** 6 contenedores unificados (core [nginx+frontend+backend] + redis × 3 proyectos)

*Decisión correcta:* Reduce complejidad de orquestación, simplifica networking, baja latencia (todo en同一 container).  
*Trade-off:* Mayor tamaño de imagen individual, acoplamiento nginx-backend.

---

## 3. Análisis de Componentes

### 3.1 Backend (FastAPI)

**Estructura:** 33 archivos Python, modular por capas (core → api → docker_layer → ai_layer → schemas)

#### Fortalezas:
- Separación clara de responsabilidades (core, api, schemas, docker_layer)
- Uso de Pydantic Settings para configuración por entorno
- Rate limiting en WebSocket manager
- Sanitización de container IDs (regex + allowlist de acciones)
- Singleton del cliente Docker evita conexiones redundantes

#### Debilidades:
- **Múltiples alias de rutas:** `/health`, `/healthz`, `/api/health`, `/system`, `/api/system`, `/stats`, `/api/stats`, `/stats/host` — 8 URLs para ~3 endpoints reales
- **AI providers todos stub:** ClaudeProvider, OpenAIProvider, OllamaProvider, LocalProvider devuelven datos vacíos
- **Dos registros de providers:** `ai_layer/orchestration/registry.py` y `providers/registry.py` duplican funcionalidad
- **Rutas hardcodeadas:** `claude_collector.py` usa `C:\Users\je416\AppData\Local\AnthropicClaude\` — no funciona en Linux/otros equipos
- **Sin autenticación:** Cualquiera con acceso a la red puede ejecutar `POST /containers/{id}/start`

### 3.2 Frontend (Flutter Web)

**Archivo principal:** `frontend/lib/main.dart` — 1246 líneas, single-file (antipatrón)

#### Fortalezas:
- UI funcional con 4 vistas (infrastructure, AI systems, agents, automations)
- Sparklines de CPU con Canvas custom
- Polling periódico (6s) mantiene datos frescos
- Manejo de estados: loading, error, datos

#### Debilidades:
- **Monolito de 1246 líneas** en un solo archivo — viola principios de mantenibilidad
- **Sin tests unitarios** de la UI (solo widget test genérico)
- **Título desactualizado:** "TAVERAS // SOLUTIONS" (ya no aplica)
- **Interfaz en inglés** — no coincide con el público objetivo hispanohablante
- **Hardcodeo de URLs:** las rutas API están quemadas en el código
- **Automations view** es placeholder ("Coming soon")

### 3.3 Frontend Legacy (HTML)

**Archivo:** `frontend/web/legacy.html` — 237 líneas, español, funcional

- Ventaja: funciona sin Flutter, carga instantánea
- Datos actualizados cada 5s vía fetch
- Endpoints inconsistentes con el Flutter dashboard

### 3.4 Infraestructura Docker

#### Dockerfile unificado (`infra/antigravity-core/Dockerfile`):
- Base `python:3.12-slim` (~120 MB) + nginx — imagen final ~350 MB
- Entrypoint bash arranca nginx + uvicorn en paralelo
- Healthcheck con curl cada 30s
- Fix aplicado: `rm /etc/nginx/sites-enabled/default` para evitar conflicto Debian

#### Docker Compose:
- Redes separadas por proyecto (antigravity, mobile, jarvis) — buen aislamiento
- Docker socket montado en core containers — riesgo de seguridad conocido pero necesario
- Volúmenes nombrados para Redis — persistencia correcta
- Sin límites de recursos (memoria/CPU) en los servicios

### 3.5 Acceso Remoto

| Método | Estado | Puertos |
|---|---|---|
| LAN (192.168.100.52) | Parcial — requiere firewall rule + portproxy admin | 3000, 3001, 3002 |
| Tailscale (100.80.145.21) | Parcial — requiere firewall rule | 3000, 3001, 3002 |
| localtunnel | Funcional — pero lento y URLs cambian | 3000, 3001, 3002 |

---

## 4. Hallazgos de Auditoría

### 🔴 Críticos

| ID | Hallazgo | Impacto | Archivo |
|---|---|---|---|
| C-01 | Sin autenticación en endpoints Docker | Cualquier cliente en la red puede manipular contenedores | `api/routes/containers.py` |
| C-02 | Docker socket montado sin restricciones | Escalada de privilegios si un contenedor es comprometido | `docker-compose.yml` |
| C-03 | Ruta Windows hardcodeada en collector | No funciona fuera de la máquina del desarrollador | `ai_layer/claude_collector.py:27` |

### 🟡 Altos

| ID | Hallazgo | Impacto | Archivo |
|---|---|---|---|
| A-01 | 8 alias de ruta para 3 endpoints | Mantenimiento confuso, posible caching inconsistente | `api/routes/health.py` |
| A-02 | ProviderRegistry duplicado | Código muerto, confusión de capas | `ai_layer/.../registry.py` y `providers/registry.py` |
| A-03 | Flutter app monolítica (1246 líneas) | Difícil de mantener, testear o extender | `lib/main.dart` |
| A-04 | Stubs AI sin implementación | La vista AI Systems no muestra datos reales | `ai_layer/providers/*.py` |
| A-05 | Sin tests automatizados | Riesgo alto de regresiones | — |

### 🟢 Medios

| ID | Hallazgo | Impacto | Archivo |
|---|---|---|---|
| M-01 | Título "TAVERAS // SOLUTIONS" desactualizado | Confusión de marca | `lib/main.dart:28` |
| M-02 | Interfaz en inglés para público hispano | Fricción de usuario | `lib/main.dart` |
| M-03 | URLs de API hardcodeadas | Dificulta cambios de deploy | `lib/main.dart` |
| M-04 | Sin límites de recursos en compose | Un container puede hambrear al sistema | `docker-compose.yml` |
| M-05 | Polling cada 6s sin backpressure | Sobre-carga en red con muchos contenedores | `lib/main.dart` |
| M-06 | Redis expuesto sin autenticación | Dentro de la red Docker, sin contraseña | `docker-compose.yml` |

### 🔵 Bajos

| ID | Hallazgo | Impacto | Archivo |
|---|---|---|---|
| B-01 | `legacy.html` usa endpoints diferentes al Flutter | Inconsistencia de datos | `web/legacy.html` |
| B-02 | Placeholder "Coming Soon" en Automations | Percepción de incompletitud | `lib/main.dart` |
| B-03 | Sin .env real (solo .env.example) | Configuración no versionada | `backend/` |
| B-04 | Sin .ai/ (Antigravity no inicializado) | Falta de trazabilidad de sesiones | — |

---

## 5. Métricas de Performance

### Consumo de Recursos

| Métrica | Valor |
|---|---|
| RAM total contenedores | ~245 MB |
| Disco imágenes activas | 2.4 GB |
| Build cache | 0 (limpiado) |
| Docker daemon (WSL2) | ~104 MB |
| Contenedores activos | 6 |
| Tiempo de respuesta /health | <100ms |
| Polling frontend | Cada 6s |

### Historial de Sesiones

| Recurso | Cantidad liberada |
|---|---|
| Build cache Docker | 22 GB |
| Imágenes no usadas | 19 GB |
| **Total** | **~41 GB** |

---

## 6. Recomendaciones Priorizadas

### Hacer ahora (impacto inmediato)

1. **Agregar autenticación básica** en endpoints críticos — API key simple via header o middleware FastAPI
2. **Unificar rutas API:** eliminar duplicados, mantener solo `/health`, `/api/containers`, `/system/info`, `/stats/host`
3. **Actualizar título y marca** en Flutter app — cambiar "TAVERAS // SOLUTIONS" por "Antigravity"

### Hacer pronto (próxima sesión)

4. **Traducir Flutter app a español** — toda la interfaz
5. **Refactorizar `main.dart`** — dividir en archivos separados (dashboard/, cards/, views/)
6. **Configurar límites de recursos** en docker-compose (`mem_limit`, `cpus`)
7. **Agregar contraseña a Redis** en producción

### Hacer después (mejora continua)

8. **Implementar al menos un provider AI real** (Ollama es el más fácil por ser local)
9. **Escribir tests** para rutas API y docker_layer
10. **Hacer configurable la ruta de Claude** via variable de entorno
11. **Implementar backpressure** en WebSocket manager
12. **Inicializar Antigravity** (`.ai/`) para trazabilidad de sesiones

---

## 7. Plan de Acción Sugerido

```
Semana 1: 🔴 Críticos
  □ C-01: Autenticación básica en endpoints Docker
  □ C-03: Ruta Claude configurable por env
  □ A-01: Unificar rutas API duplicadas

Semana 2: 🟡 Altos  
  □ M-01: Actualizar branding y título
  □ M-02: Traducir Flutter a español
  □ A-03: Refactorizar main.dart en módulos

Semana 3: 🟡 Altos
  □ M-04: Agregar límites de recursos
  □ M-06: Redis con autenticación
  □ A-05: Tests básicos de API

Semana 4+: Mejora continua
  □ A-02: Eliminar ProviderRegistry duplicado
  □ A-04: Implementar provider Ollama
  □ B-01: Sincronizar legacy.html con endpoints actuales
```

---

## 8. Conclusión

El proyecto Antigravity Control Center es funcional y estable en su propósito principal (monitoreo de infraestructura Docker). La simplificación a 6 contenedores fue un acierto arquitectónico. Sin embargo, la capa AI está incompleta, la seguridad es insuficiente para producción expuesta a internet, y hay deuda técnica significativa en el frontend (monolito Flutter de 1246 líneas) y en la duplicación de capas de providers.

**Puntuación de madurez: 5.5/10** — Funcional pero con brechas de seguridad, testing y completitud que deben abordarse antes de exponer a internet sin restricciones.
