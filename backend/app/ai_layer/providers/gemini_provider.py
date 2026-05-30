from typing import Any

from app.ai_layer.providers.remote_provider import RemoteProvider


class GeminiProvider(RemoteProvider):
    provider_id = "gemini"
    provider_type = "hosted"
    base_url = "https://generativelanguage.googleapis.com"
    models_path = "/v1/models"

    @property
    def auth_headers(self) -> dict[str, str]:
        return {}

    @property
    def auth_params(self) -> dict[str, str]:
        return {"key": self.api_key}

    def parse_models(self, data: dict) -> list[dict[str, Any]]:
        raw = data.get("models") or []
        return [
            {
                "id": m.get("name", "").replace("models/", ""),
                "name": m.get("displayName") or m.get("name"),
            }
            for m in raw[:20]
        ]
