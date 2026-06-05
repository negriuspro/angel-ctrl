from __future__ import annotations

import os
import socket
from contextlib import closing


def get_local_ip() -> str:
    """Return the host LAN IP.
    
    Checks HOST_IP env var first (set in docker-compose to bypass Docker network IP).
    Falls back to socket detection which inside containers returns the bridge IP.
    """
    host_ip = os.getenv("HOST_IP", "").strip()
    if host_ip:
        return host_ip
    with closing(socket.socket(socket.AF_INET, socket.SOCK_DGRAM)) as sock:
        try:
            sock.connect(("1.1.1.1", 80))
            return sock.getsockname()[0]
        except OSError:
            return "127.0.0.1"
