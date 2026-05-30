from __future__ import annotations

import asyncio
from collections.abc import Iterator
from typing import Any

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.core.config import get_settings
from app.docker_layer.containers import list_containers
from app.docker_layer.logs import stream_container_logs
from app.docker_layer.metrics import get_container_metrics
from app.docker_layer.system import get_system_summary
from app.realtime.events import log_event, metrics_event, snapshot_event
from app.realtime.publishers import manager

router = APIRouter(tags=["websocket"])


async def _snapshot() -> dict:
    system, containers = await asyncio.gather(
        asyncio.to_thread(get_system_summary),
        asyncio.to_thread(list_containers),
    )
    return {"system": system, "containers": containers}


@router.websocket("/ws")
async def root_ws(ws: WebSocket) -> None:
    await system_ws(ws)


@router.websocket("/ws/system")
async def system_ws(ws: WebSocket) -> None:
    settings = get_settings()
    client_key = f"{ws.client.host}:{ws.client.port}"
    await manager.connect("system", ws)
    try:
        await ws.send_json(snapshot_event(await _snapshot()))
        while True:
            msg = await ws.receive_text()
            if not manager.allow_event(client_key, settings.websocket_rate_limit_per_minute):
                await ws.send_json({"type": "rate_limited"})
                continue
            if msg == "snapshot":
                await ws.send_json(snapshot_event(await _snapshot()))
            elif msg.startswith("metrics:"):
                container_id = msg.split(":", 1)[1].strip()
                metrics = await asyncio.to_thread(get_container_metrics, container_id)
                await ws.send_json(metrics_event(container_id, metrics))
            else:
                await ws.send_json({"type": "ack", "message": "unsupported_command"})
    except WebSocketDisconnect:
        pass
    finally:
        await manager.disconnect("system", ws)


@router.websocket("/ws/containers/{container_id}/logs")
async def container_logs_ws(ws: WebSocket, container_id: str) -> None:
    await manager.connect(f"logs:{container_id}", ws)
    try:
        await ws.send_json({"type": "connected", "container_id": container_id})
        iterator = stream_container_logs(container_id)
        while True:
            line = await asyncio.to_thread(_next_log_line, iterator)
            if line is None:
                await asyncio.sleep(0.25)
                continue
            await ws.send_json(log_event(container_id, line))
    except WebSocketDisconnect:
        pass
    finally:
        await manager.disconnect(f"logs:{container_id}", ws)


def _next_log_line(iterator: Iterator[str]) -> str | None:
    try:
        return next(iterator)
    except StopIteration:
        return None
