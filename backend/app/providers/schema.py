from typing import Any

from pydantic import BaseModel, Field


class NormalizedProviderTelemetry(BaseModel):
    provider_id: str
    provider_type: str
    model_id: str | None = None
    health: str
    latency_ms: float | None = None
    request_count: int | None = None
    token_input: int | None = None
    token_output: int | None = None
    estimated_cost_usd: float | None = None
    streaming_state: str | None = None
    capabilities: list[str] = Field(default_factory=list)
    metadata: dict[str, Any] = Field(default_factory=dict)
