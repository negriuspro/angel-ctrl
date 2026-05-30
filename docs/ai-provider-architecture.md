# AI Provider Architecture

This layer generalizes the Claude dashboard patterns into a provider-agnostic AI observability and orchestration system.

## Goals

- Normalize telemetry across all providers
- Keep credentials backend-only
- Avoid frontend rewrites when adding providers
- Support hosted and local providers with the same surface area
- Reuse monitoring concepts from Claude dashboards without binding the system to Claude

## Provider Families

- Claude
- OpenAI
- Gemini
- Grok
- Cerebras
- Ollama
- LocalAI
- vLLM
- LM Studio
- local models
- future providers

## Backend Module Layout

```text
ai_layer/
├─ providers/
│  ├─ base_provider.py
│  ├─ claude_provider.py
│  ├─ openai_provider.py
│  ├─ ollama_provider.py
│  └─ local_provider.py
├─ monitoring/
├─ orchestration/
└─ realtime/
```

## Security Rules

- Credentials remain backend-only
- Secrets are encrypted in config or secret storage
- Frontend receives only sanitized telemetry and orchestration status
- No raw provider secrets
- No unrestricted provider execution interfaces

## Realtime Contract

Normalized websocket channels should include:

- `ai.providers.status`
- `ai.agents.activity`
- `ai.tasks.events`
- `ai.models.metrics`
- `ai.sessions.active`
- `ai.tokens.stream`
- `ai.alerts`

