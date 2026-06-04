import logging

from fastapi import Header, HTTPException

from app.core.config import get_settings

_log = logging.getLogger(__name__)

_INSECURE_DEFAULTS = {"changeme", "change_me", "secret", "password", "admin"}


async def require_api_key(x_api_key: str = Header(default="")) -> None:
    settings = get_settings()
    if not settings.api_key:
        # Sin clave configurada: acceso libre (modo dev).
        # Establece API_KEY en .env para producción.
        _log.warning("[AUTH] API_KEY no configurada — acceso sin autenticación")
        return
    if settings.api_key in _INSECURE_DEFAULTS:
        _log.warning("[AUTH] API_KEY insegura detectada ('%s') — cambia el valor en .env", settings.api_key)
    if not x_api_key:
        raise HTTPException(status_code=401, detail="API key required")
    if x_api_key != settings.api_key:
        raise HTTPException(status_code=403, detail="Invalid API key")
