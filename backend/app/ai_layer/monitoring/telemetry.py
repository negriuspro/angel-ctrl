from __future__ import annotations

from typing import Any


def normalize_telemetry_event(source: str, payload: dict[str, Any]) -> dict[str, Any]:
    return {
        "source": source,
        "status": payload.get("status", "unknown"),
        "metrics": payload.get("metrics", {}),
        "events": payload.get("events", []),
        "tokens": payload.get("tokens", {}),
        "timestamp": payload.get("timestamp"),
    }

