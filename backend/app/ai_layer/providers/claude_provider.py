from __future__ import annotations

from typing import Any

from app.ai_layer.providers.base_provider import BaseProvider


class ClaudeProvider(BaseProvider):
    provider_id = "claude"
    provider_type = "hosted"

    def list_models(self) -> list[dict[str, Any]]:
        return []

    def get_status(self) -> dict[str, Any]:
        return {"provider_id": self.provider_id, "status": "unknown"}

    def get_telemetry(self) -> dict[str, Any]:
        return {"provider_id": self.provider_id, "status": "unknown", "capabilities": []}

    def get_events(self) -> list[dict[str, Any]]:
        return []

