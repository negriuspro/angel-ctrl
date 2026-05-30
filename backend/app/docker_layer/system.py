from __future__ import annotations

import os
import socket
from datetime import datetime, timezone
from typing import Any

import docker
import psutil
from docker.errors import DockerException

from app.core.network import get_local_ip
from app.docker_layer.client import get_docker_client
from app.docker_layer.containers import list_containers
from app.docker_layer.images import list_images
from app.docker_layer.networks import list_networks


def get_system_summary() -> dict[str, Any]:
    client = get_docker_client()
    info = client.info()
    return {
        "status": "ok",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "lan_ip": get_local_ip(),
        "docker": {
            "status": "ok",
            "server_version": info.get("ServerVersion"),
            "containers": info.get("Containers", 0),
            "containers_running": info.get("ContainersRunning", 0),
            "containers_paused": info.get("ContainersPaused", 0),
            "containers_stopped": info.get("ContainersStopped", 0),
            "images": info.get("Images", 0),
            "driver": info.get("Driver"),
            "logging_driver": info.get("LoggingDriver"),
        },
        "counts": {
            "containers": len(list_containers()),
            "images": len(list_images()),
            "networks": len(list_networks()),
        },
    }


def get_system_stats() -> dict[str, Any]:
    client = get_docker_client()
    info = client.info()
    return {
        "status": "ok",
        "docker": {
            "containers_running": info.get("ContainersRunning", 0),
            "containers_paused": info.get("ContainersPaused", 0),
            "containers_stopped": info.get("ContainersStopped", 0),
            "images": info.get("Images", 0),
            "cpu_cpus": info.get("NCPU", 0),
            "memory_bytes": info.get("MemTotal", 0),
        },
    }


def get_host_stats() -> dict[str, Any]:
    info = get_docker_client().info()

    cpu_pct = psutil.cpu_percent(interval=None)
    mem = psutil.virtual_memory()
    disk = psutil.disk_usage("/")
    net = psutil.net_io_counters()
    boot_ts = psutil.boot_time()
    uptime_secs = int(datetime.now().timestamp() - boot_ts) if boot_ts else 0
    load_avg = os.getloadavg() if hasattr(os, "getloadavg") else (0, 0, 0)
    proc_count = len(psutil.pids())

    return {
        "hostname": info.get("Name", socket.gethostname()),
        "lan_ip": get_local_ip(),
        "uptime_seconds": uptime_secs,
        "load_1m": round(load_avg[0], 2),
        "load_5m": round(load_avg[1], 2),
        "load_15m": round(load_avg[2], 2),
        "cpu_count": info.get("NCPU", 0),
        "cpu_percent": cpu_pct,
        "mem_total_bytes": mem.total,
        "mem_used_bytes": mem.used,
        "mem_percent": round(mem.percent, 1),
        "disk_total_bytes": disk.total,
        "disk_used_bytes": disk.used,
        "disk_percent": round(disk.percent, 1),
        "net_rx_bytes": net.bytes_recv,
        "net_tx_bytes": net.bytes_sent,
        "processes": proc_count,
        "containers_running": info.get("ContainersRunning", 0),
        "containers_total": info.get("Containers", 0),
        "docker_version": info.get("ServerVersion"),
        "os": info.get("OperatingSystem", ""),
        "kernel": info.get("KernelVersion", ""),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }

