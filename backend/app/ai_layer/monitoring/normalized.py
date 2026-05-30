from __future__ import annotations

from typing import Any


def normalize_provider_status(provider_id: str, raw: dict[str, Any]) -> dict[str, Any]:
    return {
        "provider_id": provider_id,
        "status": raw.get("status", "unknown"),
        "health": raw.get("health", "unknown"),
        "latency_ms": raw.get("latency_ms"),
        "request_count": raw.get("request_count", 0),
        "token_usage": raw.get("token_usage", {}),
        "runtime_state": raw.get("runtime_state", "idle"),
        "activity": raw.get("activity", []),
        "alerts": raw.get("alerts", []),
    }

