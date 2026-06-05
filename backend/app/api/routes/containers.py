from __future__ import annotations

import asyncio
import logging

from fastapi import APIRouter, Depends, HTTPException, Query, Request

from app.core.auth import require_api_key
from app.docker_layer.containers import inspect_container, list_containers, perform_action
from app.docker_layer.logs import get_container_logs
from app.docker_layer.metrics import get_container_metrics
from app.docker_layer.images import list_images
from app.docker_layer.networks import list_networks
from app.schemas.containers import ContainerActionResult, ContainerSummary
from app.schemas.metrics import ContainerMetrics

router = APIRouter(tags=["containers"])
_log = logging.getLogger(__name__)


@router.get("/containers", response_model=list[ContainerSummary])
async def get_containers() -> list[dict]:
    return await asyncio.to_thread(list_containers)


@router.get("/containers/{container_id}")
async def get_container(container_id: str) -> dict:
    try:
        return await asyncio.to_thread(inspect_container, container_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.post(
    "/containers/{container_id}/{action}",
    response_model=ContainerActionResult,
    dependencies=[Depends(require_api_key)],
)
async def run_container_action(
    container_id: str, action: str, request: Request
) -> dict:
    caller_ip = request.client.host if request.client else "unknown"
    _log.info(
        "[AUDIT] container_action caller=%s container=%s action=%s",
        caller_ip, container_id, action,
    )
    try:
        return await asyncio.to_thread(perform_action, container_id, action)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.get("/containers/{container_id}/logs")
async def container_logs(container_id: str, tail: int = Query(default=200, ge=1, le=2000)) -> dict:
    try:
        logs = await asyncio.to_thread(get_container_logs, container_id, tail)
        return {"id": container_id, "logs": logs}
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.get("/containers/{container_id}/metrics", response_model=ContainerMetrics)
async def container_metrics(container_id: str) -> dict:
    try:
        return await asyncio.to_thread(get_container_metrics, container_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.get("/images")
async def get_images() -> list[dict]:
    try:
        return await asyncio.to_thread(list_images)
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"Docker daemon unavailable: {exc}") from exc


@router.get("/networks")
async def get_networks() -> list[dict]:
    try:
        return await asyncio.to_thread(list_networks)
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"Docker daemon unavailable: {exc}") from exc


@router.get("/logs/{container_id}")
async def logs_alias(container_id: str, tail: int = Query(default=200, ge=1, le=2000)) -> dict:
    return await container_logs(container_id, tail=tail)
