# Antigravity Control Center

Self-hosted infrastructure control center for WSL Ubuntu with Docker Engine access through the local Unix socket only.

Development priority starts with backend infrastructure stability and secure Docker integration. The UI evolves only after the backend is stable.

Final runtime:

Tablet / Browser -> Nginx Reverse Proxy Container -> Flutter Web Static Build Container -> FastAPI Backend Container -> Docker SDK -> Local Docker Engine inside WSL Ubuntu

Operational layers:

- Infrastructure Mode
- AI Control Mode
- Agents
- Automations

Boot with:

```bash
docker compose up -d
```

## Operating Modes

### Development

- Backend runs in Docker.
- Flutter app runs through the dev override with hot reload.
- Nginx still routes browser traffic so the path shape matches production.

### Production Local

- Entire stack starts with `docker compose up -d`.
- No manual backend, frontend, or websocket service startup.
- Flutter Web is built into static assets and served by Nginx.
- FastAPI backend runs in Docker and talks to the local Docker Engine through the mounted socket.

## Security Model

Never expose Docker socket publicly.

All Docker operations must go through validated backend endpoints.

No arbitrary command execution allowed.

## Core Entry Points

- `docker compose up -d`
- `docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d`
- Windows double-click: [`start-antigravity.bat`](./start-antigravity.bat)
- Frontend: `http://<LAN-IP>:3000`
- Backend API: `http://<LAN-IP>:8080`
