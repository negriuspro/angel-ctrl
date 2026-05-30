from app.providers.base import ProviderAdapter


class ProviderRegistry:
    def __init__(self) -> None:
        self._providers: dict[str, ProviderAdapter] = {}

    def register(self, provider_id: str, provider: ProviderAdapter) -> None:
        self._providers[provider_id] = provider

    def get(self, provider_id: str) -> ProviderAdapter | None:
        return self._providers.get(provider_id)

    def list_ids(self) -> list[str]:
        return list(self._providers.keys())

