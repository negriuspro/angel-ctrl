from fastapi import APIRouter

from app.api.routes.health import router as health_router
from app.api.routes.containers import router as containers_router
from app.api.routes.websocket import router as websocket_router
from app.api.routes.ai import router as ai_router

api_router = APIRouter()
api_router.include_router(health_router)
api_router.include_router(containers_router, prefix="/api")
api_router.include_router(ai_router, prefix="/api")
api_router.include_router(websocket_router)
