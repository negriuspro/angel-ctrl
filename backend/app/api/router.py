from fastapi import APIRouter, Depends

from app.api.routes.health import router as health_router
from app.api.routes.containers import router as containers_router
from app.api.routes.websocket import router as websocket_router
from app.api.routes.ai import router as ai_router
from app.core.auth import require_api_key

api_router = APIRouter()

# /health siempre público (health checks de Docker/load-balancers)
api_router.include_router(health_router)

# Todos los endpoints de Docker y AI requieren API key
api_router.include_router(
    containers_router,
    prefix="/api",
    dependencies=[Depends(require_api_key)],
)
api_router.include_router(
    ai_router,
    prefix="/api",
    dependencies=[Depends(require_api_key)],
)

# WebSocket: rate-limited a nivel de conexión en websocket.py;
# auth por header se aplica durante el handshake HTTP
api_router.include_router(
    websocket_router,
    dependencies=[Depends(require_api_key)],
)
