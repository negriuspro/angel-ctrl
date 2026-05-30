# AI Control Mode

AI Control Mode is the orchestration layer for models, providers, agents, sessions, tasks, token streams, and AI health.

## Purpose

This mode gives the dashboard a dedicated operational surface for:

- AI agent monitoring
- model activity
- Claude integrations
- future AI providers
- task orchestration
- conversations
- token usage
- runtime states
- AI health monitoring

## UI Sections

- `AI Systems`
- `Agents`
- `Automations`

## Realtime Events

The frontend should subscribe to normalized websocket channels such as:

- `ai.providers.status`
- `ai.agents.activity`
- `ai.tasks.events`
- `ai.models.metrics`
- `ai.sessions.active`
- `ai.tokens.stream`
- `ai.alerts`

## Architectural Rule

AI Control Mode must use the same backend stability rules as Infrastructure Mode:

- validated endpoints only
- no arbitrary exec
- normalized events only
- provider-specific details isolated in adapters
- websocket snapshot plus event streaming

