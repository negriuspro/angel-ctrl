from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Any


class BaseProvider(ABC):
    provider_id: str
    provider_type: str

    @abstractmethod
    def list_models(self) -> list[dict[str, Any]]:
        raise NotImplementedError

    @abstractmethod
    def get_status(self) -> dict[str, Any]:
        raise NotImplementedError

    @abstractmethod
    def get_telemetry(self) -> dict[str, Any]:
        raise NotImplementedError

    @abstractmethod
    def get_events(self) -> list[dict[str, Any]]:
        raise NotImplementedError

