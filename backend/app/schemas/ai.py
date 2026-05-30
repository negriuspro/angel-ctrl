from __future__ import annotations

from pydantic import BaseModel, Field


class AIProviderStatus(BaseModel):
    provider_id: str
    status: str
    health: str | None = None
    latency_ms: float | None = None
    request_count: int = 0
    runtime_state: str | None = None
    activity: list[dict] = Field(default_factory=list)
    alerts: list[dict] = Field(default_factory=list)


class AIOrchestrationEvent(BaseModel):
    channel: str
    payload: dict

