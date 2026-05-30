from __future__ import annotations

from typing import Any


def snapshot_event(payload: list[dict[str, Any]]) -> dict[str, Any]:
    return {"type": "snapshot", "payload": payload}


def log_event(container_id: str, line: str) -> dict[str, Any]:
    return {"type": "container.log", "container_id": container_id, "line": line}


def metrics_event(container_id: str, payload: dict[str, Any]) -> dict[str, Any]:
    return {"type": "container.metrics", "container_id": container_id, "payload": payload}
