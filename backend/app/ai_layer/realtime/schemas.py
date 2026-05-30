from __future__ import annotations

from typing import Any


def ai_snapshot_event(payload: dict[str, Any]) -> dict[str, Any]:
    return {"type": "ai.snapshot", "payload": payload}


def ai_event(channel: str, payload: dict[str, Any]) -> dict[str, Any]:
    return {"type": channel, "payload": payload}

