#!/bin/bash
# setup-ubuntu.sh — Configura la PC Ubuntu como servidor Antigravity
# Ejecutar como usuario normal (NO root): bash setup-ubuntu.sh
# El script pedirá sudo cuando sea necesario.

set -e

REPO_URL="https://github.com/TU_USUARIO/TU_REPO.git"   # <-- cambiar
DEPLOY_DIR="$HOME/antigravity"
RUNNER_DIR="$HOME/actions-runner"

echo "=== [1/5] Instalando Docker ==="
if ! command -v docker &>/dev/null; then
  sudo apt-get update -qq
  sudo apt-get install -y ca-certificates curl gnupg lsb-release
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -qq
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  sudo usermod -aG docker "$USER"
  echo "Docker instalado. IMPORTANTE: cierra sesión y vuelve a entrar para que el grupo docker aplique."
  echo "Luego ejecuta este script de nuevo."
  exit 0
else
  echo "Docker ya instalado."
fi

echo "=== [2/5] Clonando repositorio ==="
if [ ! -d "$DEPLOY_DIR" ]; then
  git clone "$REPO_URL" "$DEPLOY_DIR"
else
  echo "Repositorio ya existe en $DEPLOY_DIR"
fi

echo "=== [3/5] Configurando archivo .env ==="
if [ ! -f "$DEPLOY_DIR/.env" ]; then
  cp "$DEPLOY_DIR/.env.example" "$DEPLOY_DIR/.env" 2>/dev/null || cat > "$DEPLOY_DIR/.env" << 'EOF'
# Completar con tus API keys reales
REDIS_PASSWORD=cambia_esto
OPENROUTER_API_KEY=
GROQ_API_KEY=
CEREBRAS_API_KEY=
GEMINI_API_KEY=
SAMBANOVA_API_KEY=
EOF
  echo "Archivo .env creado. EDÍTALO antes de iniciar: nano $DEPLOY_DIR/.env"
else
  echo ".env ya existe."
fi

echo "=== [4/5] Instalando GitHub Actions self-hosted runner ==="
mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

if [ ! -f "./config.sh" ]; then
  # Descargar la última versión del runner
  RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest \
    | grep '"tag_name"' | cut -d'"' -f4 | sed 's/v//')
  curl -o actions-runner-linux-x64.tar.gz -L \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
  tar xzf actions-runner-linux-x64.tar.gz
  rm actions-runner-linux-x64.tar.gz
fi

echo ""
echo "=== [5/5] Configuración manual requerida ==="
echo ""
echo "1. Ve a tu repo en GitHub → Settings → Actions → Runners → New self-hosted runner"
echo "2. Copia el TOKEN que te da GitHub (expira en 1 hora)"
echo "3. Ejecuta:"
echo "   cd $RUNNER_DIR"
echo "   ./config.sh --url $REPO_URL --token TU_TOKEN_AQUI --name antigravity-ubuntu --unattended"
echo "   sudo ./svc.sh install"
echo "   sudo ./svc.sh start"
echo ""
echo "4. Agrega el secret DEPLOY_PATH en GitHub → Settings → Secrets → Actions:"
echo "   DEPLOY_PATH = $DEPLOY_DIR"
echo ""
echo "Setup base completado."
