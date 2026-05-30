from abc import ABC, abstractmethod
from typing import Any


class ProviderAdapter(ABC):
    @abstractmethod
    def list_models(self) -> list[dict[str, Any]]:
        raise NotImplementedError

    @abstractmethod
    def get_health(self) -> dict[str, Any]:
        raise NotImplementedError

    @abstractmethod
    def get_telemetry(self) -> dict[str, Any]:
        raise NotImplementedError

    @abstractmethod
    def stream_generation(self, prompt: str) -> Any:
        raise NotImplementedError

