# Deployment

## Production Local

```bash
docker compose up -d
```

This starts the reverse proxy, frontend runtime, backend API, and support services.

## Development Hot Reload

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

This keeps the backend inside Docker and runs the Flutter web server in hot-reload mode behind the same Nginx entrypoint.

## Implementation Order

The repository should be built in this order:

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

This keeps the system production-stable before the visual layer becomes elaborate.

## Development

- Use Docker for the backend.
- Keep Flutter hot reload available outside the production compose flow when iterating on UI.
- Keep proxy routing aligned with production so websocket and path behavior stay consistent.
