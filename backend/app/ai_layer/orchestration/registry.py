from __future__ import annotations

from app.ai_layer.providers.base_provider import BaseProvider


class ProviderRegistry:
    def __init__(self) -> None:
        self._providers: dict[str, BaseProvider] = {}

    def register(self, provider: BaseProvider) -> None:
        self._providers[provider.provider_id] = provider

    def get(self, provider_id: str) -> BaseProvider | None:
        return self._providers.get(provider_id)

    def list(self) -> list[BaseProvider]:
        return list(self._providers.values())

