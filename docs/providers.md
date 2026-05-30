# Provider System

This system treats AI vendors and local model runtimes as interchangeable provider implementations behind a common contract.

Claude is only one provider implementation among many. The dashboard must never depend on Claude-specific payloads as the primary shape.

## Supported Provider Families

- Claude
- OpenAI
- Gemini
- Grok
- Cerebras
- Ollama
- local models
- future providers

## Shared Provider Interface

Each provider adapter should implement the same conceptual operations:

- list models
- inspect capabilities
- start generation
- stream tokens or events
- report health
- report usage
- report normalized telemetry

Recommended provider families:

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

## AI Control Extensions

Provider adapters should also be able to feed normalized AI control events used by orchestration and monitoring views:

- provider health
- model availability
- active sessions
- task state
- conversation state
- token stream status
- alert state

## Adapter Boundaries

Provider-specific logic stays in adapter modules.
Shared dashboards, charts, and websocket events consume normalized objects only.

Provider credentials must remain backend-only and encrypted in config or secret storage.
The frontend only receives sanitized telemetry, metrics, events, status, and orchestration activity.
It must never see raw provider secrets, API keys, or unrestricted execution interfaces.

## UI Strategy

The frontend should render provider cards, usage panels, logs, and health indicators from normalized data.
That means new providers can be added with backend configuration and adapter registration instead of rebuilding the dashboard.

AI Control Mode should reuse the same normalized event patterns so that Claude, OpenAI, Gemini, Grok, Cerebras, Ollama, and local models appear as one coherent operating surface.
