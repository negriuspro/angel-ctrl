from pydantic import BaseModel


class ContainerSummary(BaseModel):
    id: str
    name: str
    project: str
    image: str
    status: str
    state: str | None = None
    created_at: str | None = None
    uptime_seconds: int | None = None
    restart_count: int | None = None


class ContainerActionResult(BaseModel):
    id: str
    action: str
    status: str
