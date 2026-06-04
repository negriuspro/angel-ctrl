# dev-start.ps1 — angel-ctrl en modo local (sin Docker Compose)
# Arranca: Redis tunnel → Backend (uvicorn 8080) → Frontend (flutter run 5000)
# Requiere: Python + Flutter instalados, SSH acceso al servidor
# Uso: .\dev-start.ps1

$ROOT     = $PSScriptRoot
$SERVER   = "angel@192.168.100.6"
$BACKEND  = "$ROOT\backend"
$FRONTEND = "$ROOT\frontend"

Write-Host "`n=== angel-ctrl DEV ===" -ForegroundColor Cyan

# ── 1. SSH tunnel → Redis en localhost:6379 ────────────────────────────────
Write-Host "[1/3] Tunnel Redis (localhost:6379 → servidor)..." -ForegroundColor Yellow
$tunnel = Start-Process "ssh" -ArgumentList "-N -L 6379:localhost:6379 -o StrictHostKeyChecking=no $SERVER" `
    -PassThru -WindowStyle Hidden
Write-Host "      PID tunnel: $($tunnel.Id)" -ForegroundColor DarkGray
Start-Sleep -Seconds 2

# ── 2. Backend FastAPI en puerto 8080 ─────────────────────────────────────
Write-Host "[2/3] Arrancando backend en http://localhost:8080..." -ForegroundColor Yellow
Push-Location $BACKEND
pip install -r requirements.txt -q

if (-not (Test-Path ".env")) {
    @"
APP_ENV=development
BACKEND_HOST=0.0.0.0
BACKEND_PORT=8080
# Docker Desktop en Windows (pipe nativo):
DOCKER_HOST=npipe:////./pipe/docker_engine
REDIS_URL=redis://localhost:6379/0
API_KEY=dev-local-key
CORS_ORIGINS=http://localhost:5000,http://127.0.0.1:5000
LOG_LEVEL=debug
"@ | Out-File ".env" -Encoding utf8
    Write-Host "      .env creado para dev local" -ForegroundColor DarkYellow
}
Pop-Location

Start-Process "powershell" -ArgumentList "-NoExit", "-Command",
    "cd '$BACKEND'; python -m uvicorn app.main:app --host 0.0.0.0 --port 8080 --reload"

Start-Sleep -Seconds 4

# ── 3. Frontend Flutter ────────────────────────────────────────────────────
Write-Host "[3/3] Arrancando Flutter web en http://localhost:5000..." -ForegroundColor Yellow
Push-Location $FRONTEND
Start-Process "powershell" -ArgumentList "-NoExit", "-Command",
    "cd '$FRONTEND'; flutter run -d chrome --web-port 5000"
Pop-Location

Write-Host "`n✓ angel-ctrl corriendo:" -ForegroundColor Green
Write-Host "  Frontend: http://localhost:5000" -ForegroundColor White
Write-Host "  Backend:  http://localhost:8080/health" -ForegroundColor White
Write-Host "  Redis:    tunnel ssh → 192.168.100.6" -ForegroundColor White
Write-Host "  NOTA: monitoreo de Docker usa Docker Desktop local (tus contenedores locales)`n" -ForegroundColor DarkGray
