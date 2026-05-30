from pydantic import BaseModel


class DockerSystemInfo(BaseModel):
    status: str
    lan_ip: str | None = None
    docker: dict
    counts: dict

