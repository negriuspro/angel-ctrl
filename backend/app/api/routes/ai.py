from __future__ import annotations

from fastapi import APIRouter

from app.ai_layer.claude_collector import collect as collect_claude_metrics
from app.ai_layer.providers.openrouter_provider import OpenRouterProvider
from app.ai_layer.providers.groq_provider import GroqProvider
from app.ai_layer.providers.cerebras_provider import CerebrasProvider
from app.ai_layer.providers.gemini_provider import GeminiProvider
from app.ai_layer.providers.sambanova_provider import SambaNovaProvider
from app.core.config import get_settings

router = APIRouter(tags=["ai"])

_settings = get_settings()

_PROVIDERS: list = []

if _settings.openrouter_api_key:
    _PROVIDERS.append(OpenRouterProvider(_settings.openrouter_api_key))
if _settings.groq_api_key:
    _PROVIDERS.append(GroqProvider(_settings.groq_api_key))
if _settings.cerebras_api_key:
    _PROVIDERS.append(CerebrasProvider(_settings.cerebras_api_key))
if _settings.gemini_api_key:
    _PROVIDERS.append(GeminiProvider(_settings.gemini_api_key))
if _settings.sambanova_api_key:
    _PROVIDERS.append(SambaNovaProvider(_settings.sambanova_api_key))

_KNOWN = [
    {"id": "claude",     "type": "hosted", "label": "Claude (Antigravity)"},
    {"id": "codex",      "type": "hosted", "label": "Codex (OpenAI)"},
    {"id": "gemini",     "type": "hosted", "label": "Gemini (Google)"},
    {"id": "groq",       "type": "hosted", "label": "Groq"},
    {"id": "cerebras",   "type": "hosted", "label": "Cerebras"},
    {"id": "openrouter", "type": "hosted", "label": "OpenRouter"},
    {"id": "sambanova",  "type": "hosted", "label": "SambaNova"},
]


@router.get("/ai/providers")
async def get_ai_providers() -> list[dict]:
    results: list[dict] = []

    for p in _PROVIDERS:
        try:
            telemetry = p.get_telemetry()
            status = p.get_status()
            label = next((k["label"] for k in _KNOWN if k["id"] == p.provider_id), p.provider_id)
            results.append({
                "provider_id": p.provider_id,
                "provider_type": p.provider_type,
                "label": label,
                "health": status.get("status", "unknown"),
                "models": p.list_models(),
                "capabilities": telemetry.get("capabilities", []),
                "metrics": {
                    "latency_ms": telemetry.get("latency_ms"),
                    "request_count": telemetry.get("request_count"),
                    "token_input": telemetry.get("token_input"),
                    "token_output": telemetry.get("token_output"),
                },
                "events": p.get_events()[-5:],
            })
        except Exception as exc:
            results.append({
                "provider_id": p.provider_id,
                "provider_type": getattr(p, "provider_type", "unknown"),
                "label": p.provider_id,
                "health": "error",
                "error": str(exc),
                "models": [],
                "capabilities": [],
                "metrics": {},
                "events": [],
            })

    configured_ids = {p.provider_id for p in _PROVIDERS}
    for known in _KNOWN:
        if known["id"] not in configured_ids:
            results.append({
                "provider_id": known["id"],
                "provider_type": known["type"],
                "label": known["label"],
                "health": "not_configured",
                "models": [],
                "capabilities": [],
                "metrics": {},
                "events": [],
            })

    return results


@router.get("/ai/claude/metrics")
async def get_claude_metrics() -> dict:
    from app.ai_layer.claude_collector import collect as collect_claude_metrics
    s = collect_claude_metrics()
    return {
        "has_data": s.has_data,
        "session": s.session,
        "today": s.today,
        "sparkline": s.sparkline,
    }
