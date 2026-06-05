from __future__ import annotations

import logging
import docker
from docker.client import DockerClient
from docker.errors import DockerException

from app.core.config import get_settings

logger = logging.getLogger(__name__)

_client: DockerClient | None = None


def get_docker_client() -> DockerClient:
    global _client
    if _client is None:
        settings = get_settings()
        _client = docker.DockerClient(base_url=settings.docker_host)
    return _client


def ping_docker() -> bool:
    try:
        return get_docker_client().ping()
    except Exception as exc:
        logger.debug("Docker ping failed (socket-proxy unreachable?): %s", exc)
        return False

