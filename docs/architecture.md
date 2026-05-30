# Architecture

The platform is designed to boot from Docker Compose in WSL Ubuntu and expose a tablet-friendly dashboard over the LAN.
It is intentionally provider-agnostic: Claude is one provider implementation, not the system model.

## Development Priority

1. Backend infrastructure stability
2. Secure Docker SDK integration
3. WebSocket realtime architecture
4. Stable metrics/log streaming
5. API normalization
6. Flutter dashboard functionality
7. AI provider abstraction layer
8. Claude dashboard adaptation
9. Multi-provider AI monitoring
10. Advanced sci-fi UX layer

The infrastructure layer is the highest priority. The cinematic UI is the last layer.

## Operational Modes

The dashboard must support two top-level operational layers that feel like different views of the same system:

1. Infrastructure Mode
2. AI Control Mode

Recommended navigation sections:

- `Infrastructure`
- `AI Systems`
- `Agents`
- `Automations`

The interface should switch between these layers without changing the core application shell or forcing major UI rewrites.

## Final Self-Hosted Runtime

Tablet / Browser -> Nginx Reverse Proxy Container -> Flutter Web Static Build Container -> FastAPI Backend Container -> Docker SDK -> Local Docker Engine inside WSL Ubuntu -> Containers

The user should only need:

```bash
docker compose up -d
```

to boot the full Antigravity ecosystem.

## Runtime Flow

Tablet or browser -> Nginx reverse proxy -> Flutter Web static container -> FastAPI backend container -> local Docker Engine via mounted Unix socket.

For AI provider traffic, the flow is:

Dashboard -> Provider API layer -> normalized provider adapters -> provider backends such as Claude, OpenAI, Gemini, Grok, Cerebras, Ollama, or local models.

For AI control traffic, the flow is:

Dashboard -> AI control API layer -> normalized AI runtime telemetry -> provider adapters and orchestration services -> conversations, tasks, sessions, and model activity.

## Hard Security Rules

Never expose Docker socket publicly.

All Docker operations must go through validated backend endpoints.

No arbitrary command execution allowed.

## Service Responsibilities

- `nginx`: reverse proxy, gzip, SPA routing, websocket upgrades.
- `frontend`: builds and serves the compiled Flutter Web app as static assets.
- `backend`: FastAPI API, websocket broadcaster, Docker SDK access, metrics, logs, container validation.
- `redis`: future pub/sub, queueing, cache, and websocket fanout support.

## Provider Abstraction

The backend should expose a normalized provider contract so the UI works the same way across Claude, OpenAI, Gemini, Grok, Cerebras, Ollama, and local models.

Core shared concepts:

- `provider_id`
- `provider_type`
- `model_id`
- `capabilities`
- `telemetry`
- `conversation`
- `generation`
- `health`
- `usage`
- `cost`
- `latency`
- `streaming_state`

Claude-specific details must stay inside a Claude adapter and must not leak into shared UI state or the top-level architecture.

## AI Control Model

AI Control Mode should expose normalized runtime concepts that work across Claude, OpenAI, Gemini, Grok, Cerebras, Ollama, local models, and future providers.

Core shared concepts:

- `ai_provider_id`
- `agent_id`
- `session_id`
- `task_id`
- `model_id`
- `conversation_id`
- `token_usage`
- `runtime_state`
- `health`
- `activity`
- `events`
- `alerts`
- `telemetry`

The UI should render these concepts generically so a new provider can be added without a redesign.

## Normalized Telemetry

Provider telemetry should be converted into a shared schema before the frontend sees it.

Examples of normalized fields:

- response latency
- request count
- token usage
- cache hit state
- streaming status
- error class
- model availability
- rate-limit state
- estimated cost

AI runtime telemetry should be normalized into the same event and snapshot model used by infrastructure, but with AI-specific channel names and payloads.

This lets the dashboard render one consistent provider operations view without provider-specific branching in every widget.

## Frontend Compatibility Rule

The Flutter UI should bind to normalized provider and telemetry models, not to Claude-only response shapes.
That keeps future providers additive rather than invasive.

## Realtime Channels

Infrastructure mode channels:

- `system.status`
- `containers.snapshot`
- `containers.events`
- `containers.metrics`
- `containers.logs`
- `network.status`
- `alerts.security`

AI Control Mode channels:

- `ai.providers.status`
- `ai.agents.activity`
- `ai.tasks.events`
- `ai.models.metrics`
- `ai.sessions.active`
- `ai.tokens.stream`
- `ai.alerts`

These channels should be backed by the same websocket infrastructure and fanout logic, not by separate ad hoc transports.

## Immediate Focus

The near-term implementation should concentrate on backend stability in WSL Ubuntu:

- secure Docker SDK wiring
- validated container operations
- websocket event delivery
- log streaming
- metrics collection
- API normalization

Frontend work should remain incremental until the backend layer is stable.

## WSL Notes

- Bind services to `0.0.0.0`.
- Reach the UI through the WSL host LAN IP, not localhost.
- Keep Docker access local to the backend container only.
- The Docker socket must be mounted only into the backend container.
- The frontend must never talk to Docker directly.
