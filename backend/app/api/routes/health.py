from fastapi import APIRouter

from app.core.network import get_local_ip
from app.docker_layer.client import ping_docker
from app.docker_layer.system import get_host_stats, get_system_stats, get_system_summary

router = APIRouter(tags=["health"])


@router.get("/health")
async def health() -> dict:
    return {"status": "ok", "docker": "ok" if ping_docker() else "unavailable"}


@router.get("/healthz")
async def healthz() -> dict:
    return {"status": "ok"}


@router.get("/api/health")
async def api_health() -> dict:
    return {"status": "ok", "docker": "ok" if ping_docker() else "unavailable"}


@router.get("/system/info")
async def system_info() -> dict:
    return get_system_summary()


@router.get("/api/system")
async def api_system() -> dict:
    return get_system_summary()


@router.get("/system")
async def system() -> dict:
    return get_system_summary()


@router.get("/api/stats")
async def api_stats() -> dict:
    return get_system_stats()


@router.get("/stats")
async def stats() -> dict:
    return get_system_stats()


@router.get("/api/stats/host")
async def api_stats_host() -> dict:
    return get_host_stats()


@router.get("/stats/host")
async def stats_host() -> dict:
    return get_host_stats()
