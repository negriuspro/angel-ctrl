from __future__ import annotations

import asyncio

from fastapi import APIRouter, HTTPException

from app.core.network import get_local_ip
from app.docker_layer.client import ping_docker
from app.docker_layer.system import get_host_stats, get_system_stats, get_system_summary

router = APIRouter(tags=["health"])


@router.get("/health")
async def health() -> dict:
    ok = await asyncio.to_thread(ping_docker)
    return {"status": "ok", "docker": "ok" if ok else "unavailable"}


@router.get("/healthz")
async def healthz() -> dict:
    return {"status": "ok"}


@router.get("/api/health")
async def api_health() -> dict:
    ok = await asyncio.to_thread(ping_docker)
    return {"status": "ok", "docker": "ok" if ok else "unavailable"}


@router.get("/system/info")
async def system_info() -> dict:
    try:
        return await asyncio.to_thread(get_system_summary)
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"Docker unavailable: {exc}") from exc


@router.get("/api/system")
async def api_system() -> dict:
    try:
        return await asyncio.to_thread(get_system_summary)
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"Docker unavailable: {exc}") from exc


@router.get("/system")
async def system() -> dict:
    try:
        return await asyncio.to_thread(get_system_summary)
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"Docker unavailable: {exc}") from exc


@router.get("/api/stats")
async def api_stats() -> dict:
    try:
        return await asyncio.to_thread(get_system_stats)
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"Docker unavailable: {exc}") from exc


@router.get("/stats")
async def stats() -> dict:
    try:
        return await asyncio.to_thread(get_system_stats)
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"Docker unavailable: {exc}") from exc


@router.get("/api/stats/host")
async def api_stats_host() -> dict:
    try:
        return await asyncio.to_thread(get_host_stats)
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"Stats unavailable: {exc}") from exc


@router.get("/stats/host")
async def stats_host() -> dict:
    try:
        return await asyncio.to_thread(get_host_stats)
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"Stats unavailable: {exc}") from exc
