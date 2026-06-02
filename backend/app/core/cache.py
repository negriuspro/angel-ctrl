from __future__ import annotations

import json
import logging
import time
from typing import Any

import redis.asyncio as aioredis

from app.core.config import get_settings

logger = logging.getLogger(__name__)

_redis_client: aioredis.Redis | None = None
_redis_failed_at: float = 0.0
_REDIS_RETRY_COOLDOWN = 30.0  # seconds between reconnection attempts after a failure


class TTLCache:
    """In-memory TTL cache — used as Redis fallback."""

    def __init__(self, default_ttl: float = 12.0) -> None:
        self._store: dict[str, tuple[Any, float]] = {}
        self._default_ttl = default_ttl

    def get(self, key: str) -> Any | None:
        entry = self._store.get(key)
        if entry is None:
            return None
        val, expires_at = entry
        if time.monotonic() > expires_at:
            del self._store[key]
            return None
        return val

    def set(self, key: str, value: Any, ttl: float | None = None) -> None:
        self._store[key] = (value, time.monotonic() + (ttl or self._default_ttl))

    def delete(self, key: str) -> None:
        self._store.pop(key, None)

    def clear(self) -> None:
        self._store.clear()


_memory_cache = TTLCache(default_ttl=12.0)


def memory_cache() -> TTLCache:
    return _memory_cache


async def get_redis() -> aioredis.Redis | None:
    global _redis_client, _redis_failed_at
    if _redis_client is not None:
        return _redis_client
    # Avoid hammering Redis with reconnects — wait _REDIS_RETRY_COOLDOWN after a failure
    if time.monotonic() - _redis_failed_at < _REDIS_RETRY_COOLDOWN:
        return None
    settings = get_settings()
    if not settings.redis_url:
        return None
    try:
        client: aioredis.Redis = aioredis.from_url(
            settings.redis_url,
            decode_responses=True,
            socket_connect_timeout=3,
            socket_timeout=3,
        )
        await client.ping()
        _redis_client = client
        _redis_failed_at = 0.0
        logger.info("Redis cache connected at %s", settings.redis_url)
        return _redis_client
    except Exception as exc:
        _redis_failed_at = time.monotonic()
        logger.warning("Redis unavailable, using in-memory cache: %s", exc)
        return None


async def close_redis() -> None:
    global _redis_client
    if _redis_client is not None:
        await _redis_client.aclose()
        _redis_client = None
        logger.info("Redis connection closed")


async def cache_get(key: str) -> Any | None:
    redis = await get_redis()
    if redis:
        try:
            raw = await redis.get(key)
            return json.loads(raw) if raw else None
        except Exception:
            pass
    return memory_cache().get(key)


async def cache_set(key: str, value: Any, ttl: int = 12) -> None:
    redis = await get_redis()
    if redis:
        try:
            await redis.setex(key, ttl, json.dumps(value, default=str))
            return
        except Exception:
            pass
    memory_cache().set(key, value, ttl=float(ttl))
