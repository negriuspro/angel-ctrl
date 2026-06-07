from __future__ import annotations

import httpx

from app.ai_layer.providers.remote_provider import RemoteProvider

_CREDITS_TIMEOUT = 8.0


class OpenRouterProvider(RemoteProvider):
    provider_id = "openrouter"
    provider_type = "hosted"
    base_url = "https://openrouter.ai/api"

    def __init__(self, api_key: str) -> None:
        super().__init__(api_key)
        self._total_usage: float | None = None
        self._total_credits: float | None = None

    def _do_refresh(self) -> None:
        super()._do_refresh()
        # OpenRouter expone gasto real acumulado por API key vía /v1/credits
        # (a diferencia de los demás proveedores, que no tienen endpoint de uso).
        try:
            resp = httpx.get(
                f"{self.base_url.rstrip('/')}/v1/credits",
                headers=self.auth_headers,
                timeout=_CREDITS_TIMEOUT,
            )
            if resp.status_code == 200:
                data = (resp.json() or {}).get("data") or {}
                with self._lock:
                    self._total_usage = data.get("total_usage")
                    self._total_credits = data.get("total_credits")
        except Exception:
            pass

    def get_telemetry(self) -> dict:
        telemetry = super().get_telemetry()
        with self._lock:
            usage = self._total_usage
            credits = self._total_credits
        telemetry["cost_total"] = usage
        # Solo tiene sentido mostrar "crédito restante" si la cuenta tiene
        # saldo prepago; en cuentas pay-as-you-go total_credits es 0 y la
        # resta daría un número negativo confuso.
        telemetry["credits_remaining"] = (
            round(credits - usage, 6)
            if usage is not None and credits is not None and credits > 0
            else None
        )
        return telemetry
