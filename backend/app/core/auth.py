import logging

from fastapi import Header, HTTPException

from app.core.config import get_settings

_log = logging.getLogger(__name__)

# Valores que indican que API_KEY no fue configurada correctamente.
# Si la clave activa coincide con alguno → bloquear todas las peticiones.
_INSECURE_DEFAULTS = {
    "changeme", "change_me", "secret", "password", "admin",
    "CAMBIA_ESTO", "cambia_esto", "cambia_esto_por_una_clave_segura",
    "CAMBIA_ESTO_POR_UNA_CLAVE_SEGURA",
}


async def require_api_key(x_api_key: str = Header(default="")) -> None:
    settings = get_settings()
    if not settings.api_key or settings.api_key in _INSECURE_DEFAULTS:
        _log.error(
            "[AUTH] API_KEY no configurada o insegura ('%s') — petición bloqueada. "
            "Establece una clave fuerte en .env",
            settings.api_key or "<vacía>",
        )
        raise HTTPException(
            status_code=503,
            detail="Server misconfigured: set a secure API_KEY in .env",
        )
    if not x_api_key:
        raise HTTPException(status_code=401, detail="API key required")
    if x_api_key != settings.api_key:
        raise HTTPException(status_code=403, detail="Invalid API key")
