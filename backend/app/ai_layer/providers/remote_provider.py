from __future__ import annotations

import threading
import time
from typing import Any

import httpx

from app.ai_layer.providers.base_provider import BaseProvider

_REFRESH_INTERVAL = 120.0  # check each provider every 2 minutes
_REQUEST_TIMEOUT = 8.0


class RemoteProvider(BaseProvider):
    provider_id: str = "remote"
    provider_type: str = "hosted"
    base_url: str = ""
    models_path: str = "/v1/models"

    def __init__(self, api_key: str) -> None:
        self.api_key = api_key
        self._models_cache: list[dict[str, Any]] = []
        self._status = "unknown"
        self._latency_ms: float | None = None
        self._request_count: int = 0
        self._lock = threading.Lock()
        self._last_refresh: float = 0
        self._refresh_thread: threading.Thread | None = None
        self._start_background_refresh()

    def _start_background_refresh(self) -> None:
        self._refresh_thread = threading.Thread(
            target=self._background_loop,
            daemon=True,
            name=f"refresh-{self.provider_id}",
        )
        self._refresh_thread.start()

    def _background_loop(self) -> None:
        while True:
            self._do_refresh()
            time.sleep(_REFRESH_INTERVAL)

    def _do_refresh(self) -> None:
        try:
            t0 = time.time()
            url = self.base_url.rstrip("/") + "/" + self.models_path.lstrip("/")
            resp = httpx.get(
                url,
                headers=self.auth_headers,
                params=self.auth_params,
                timeout=_REQUEST_TIMEOUT,
            )
            latency = round((time.time() - t0) * 1000, 1)
            if resp.status_code == 200:
                models = self.parse_models(resp.json())
                with self._lock:
                    self._status = "ok"
                    self._latency_ms = latency
                    self._models_cache = models
                    self._request_count += 1
                    self._last_refresh = time.time()
            elif resp.status_code == 429:
                with self._lock:
                    self._status = "rate_limited"
                    self._latency_ms = latency
            else:
                with self._lock:
                    self._status = "error"
        except httpx.TimeoutException:
            with self._lock:
                self._status = "offline"
        except Exception:
            with self._lock:
                self._status = "error"

    @property
    def auth_headers(self) -> dict[str, str]:
        return {"Authorization": f"Bearer {self.api_key}"}

    @property
    def auth_params(self) -> dict[str, str]:
        return {}

    def parse_models(self, data: dict) -> list[dict[str, Any]]:
        raw = data.get("data") or []
        return [
            {"id": m.get("id"), "name": m.get("name") or m.get("id")} for m in raw[:20]
        ]

    def list_models(self) -> list[dict[str, Any]]:
        with self._lock:
            return list(self._models_cache)

    def get_status(self) -> dict[str, Any]:
        with self._lock:
            return {"provider_id": self.provider_id, "status": self._status}

    def get_telemetry(self) -> dict[str, Any]:
        with self._lock:
            return {
                "provider_id": self.provider_id,
                "status": self._status,
                "latency_ms": self._latency_ms,
                "request_count": self._request_count,
                # Ninguno de estos proveedores expone uso real por API key sin
                # proxyear el tráfico de chat; reportar None (no "0") para que
                # el frontend distinga "no se rastrea" de "consumo real cero".
                "token_input": None,
                "token_output": None,
                "capabilities": ["chat"],
            }

    def get_events(self) -> list[dict[str, Any]]:
        return []
