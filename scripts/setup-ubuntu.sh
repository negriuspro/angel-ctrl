#!/bin/bash
# ══════════════════════════════════════════════════════════════════
#  setup-ubuntu.sh — Setup inicial en Ubuntu Server
#  Ejecutar: bash setup-ubuntu.sh
#  NO ejecutar como root. Pide sudo internamente cuando necesita.
# ══════════════════════════════════════════════════════════════════
set -euo pipefail

REPO_URL="https://github.com/negriuspro/angel-ctrl.git"
DEPLOY_DIR="$HOME/projects/angel-ctrl"
RUNNER_DIR="$HOME/actions-runner"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ── 1. Docker ──────────────────────────────────────────────────────
info "Verificando Docker..."
if ! command -v docker &>/dev/null; then
    warn "Docker no encontrado. Instalando..."
    sudo apt-get update -qq
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo usermod -aG docker "$USER"
    warn "Docker instalado. Cierra sesion y vuelve a entrar, luego ejecuta este script de nuevo."
    exit 0
else
    info "Docker ya instalado."
fi

if ! groups | grep -q docker; then
    sudo usermod -aG docker "$USER"
    error "Anadido al grupo docker. Cierra sesion y vuelve a entrar."
fi

# ── 2. Clonar repo ────────────────────────────────────────────────
info "Configurando repositorio..."
mkdir -p "$(dirname "$DEPLOY_DIR")"
if [ ! -d "$DEPLOY_DIR/.git" ]; then
    git clone "$REPO_URL" "$DEPLOY_DIR"
    info "Repo clonado en $DEPLOY_DIR"
else
    info "Repo ya existe. Actualizando..."
    git -C "$DEPLOY_DIR" pull origin main
fi

# ── 3. Archivo .env ───────────────────────────────────────────────
info "Configurando .env..."
if [ ! -f "$DEPLOY_DIR/.env" ]; then
    cp "$DEPLOY_DIR/.env.example" "$DEPLOY_DIR/.env"

    API_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
    REDIS_PASS=$(python3 -c "import secrets; print(secrets.token_hex(24))")
    SERVER_IP=$(hostname -I | awk '{print $1}')

    sed -i "s|API_KEY=CAMBIA_ESTO|API_KEY=${API_KEY}|" "$DEPLOY_DIR/.env"
    sed -i "s|REDIS_PASSWORD=CAMBIA_ESTO|REDIS_PASSWORD=${REDIS_PASS}|" "$DEPLOY_DIR/.env"
    sed -i "s|CORS_ORIGINS=.*|CORS_ORIGINS=http://localhost:3000,http://127.0.0.1:3000,http://${SERVER_IP}:3000|" "$DEPLOY_DIR/.env"
    sed -i "s|CLAUDE_DATA_PATH=.*|CLAUDE_DATA_PATH=${HOME}/.claude|" "$DEPLOY_DIR/.env"

    warn ".env generado con claves aleatorias."
    warn "Edita el .env para agregar tus API keys:"
    warn "  nano $DEPLOY_DIR/.env"
else
    info ".env ya existe."
fi

# ── 4. Directorio .claude ─────────────────────────────────────────
mkdir -p "$HOME/.claude/projects"
info "Directorio $HOME/.claude listo."

# ── 5. GitHub Actions Runner ──────────────────────────────────────
info "Descargando GitHub Actions runner..."
mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

if [ ! -f "./config.sh" ]; then
    RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest \
        | grep '"tag_name"' | cut -d'"' -f4 | sed 's/v//')
    curl -fsSL -o runner.tar.gz \
        "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
    tar xzf runner.tar.gz
    rm runner.tar.gz
    info "Runner v${RUNNER_VERSION} descargado."
else
    info "Runner ya descargado."
fi

# ── 6. Instrucciones finales ──────────────────────────────────────
echo ""
echo "======================================================"
echo "  PASOS FINALES (manuales)"
echo "======================================================"
echo ""
echo "1. Agrega tus API keys:"
echo "   nano $DEPLOY_DIR/.env"
echo ""
echo "2. Configura el runner:"
echo "   -> https://github.com/negriuspro/angel-ctrl/settings/actions/runners/new"
echo "   -> Selecciona Linux x64, copia el token y ejecuta:"
echo ""
echo "   cd $RUNNER_DIR"
echo "   ./config.sh --url $REPO_URL --token TU_TOKEN --name angel-ubuntu --unattended"
echo "   sudo ./svc.sh install && sudo ./svc.sh start"
echo ""
echo "3. Agrega el secret DEPLOY_PATH en GitHub:"
echo "   -> https://github.com/negriuspro/angel-ctrl/settings/secrets/actions"
echo "   -> DEPLOY_PATH = $DEPLOY_DIR"
echo ""
echo "4. Primer deploy:"
echo "   cd $DEPLOY_DIR && bash scripts/deploy.sh"
echo ""
echo "======================================================"
