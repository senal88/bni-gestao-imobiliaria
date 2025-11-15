#!/usr/bin/env bash
# =========================================================
#  FRONTEND REPO GENERATOR v1.0
#  Gera automaticamente um ambiente de desenvolvimento completo
#  com base nas definições do arquivo frontend-project-context.md
# =========================================================

set -e

# --- Funções auxiliares ------------------------------
extract() {
  grep -A 1 "^**${1}:**" frontend-project-context.md | tail -n 1 | xargs
}

extract_table() {
  grep -E "^\\| \\*\\*${1}\\*\\* \\|" frontend-project-context.md | awk -F'|' '{print $3}' | cut -d '<' -f 2 | cut -d '/' -f 1 | xargs
}

# --- Leitura de parâmetros ----------------------------
PROJECT_NAME=$(extract "PROJECT_NAME")
STACK_TYPE=$(extract_table "STACK_TYPE")
LANGUAGE=$(extract_table "LANGUAGE")
PKG_MANAGER=$(extract_table "PKG_MANAGER")
STYLE_LIB=$(extract_table "STYLE_LIB")
DEPLOY_TARGET=$(extract_table "DEPLOY_TARGET")
CI_PROVIDER=$(extract_table "CI_PROVIDER")
AUTOMATION_TOOL=$(extract_table "AUTOMATION_TOOL")
HOST_ENV=$(extract_table "HOST_ENV")

# --- Validação mínima ---------------------------------
if [ -z "$PROJECT_NAME" ]; then
  echo "❌ ERRO: PROJECT_NAME não definido no arquivo frontend-project-context.md"
  exit 1
fi

# --- Criação de diretórios base ------------------------
echo "📁 Criando estrutura do projeto: $PROJECT_NAME ..."
mkdir -p $PROJECT_NAME/{src/{api,components,context,hooks,pages,services,styles,utils},public,config,docker,.github/workflows,.vscode}

cd $PROJECT_NAME

# --- Inicialização do projeto -------------------------
echo "⚙️  Inicializando projeto ${STACK_TYPE} (${LANGUAGE}) ..."
if [ "$STACK_TYPE" = "react" ]; then
  npx create-vite@latest . --template react-${LANGUAGE}
elif [ "$STACK_TYPE" = "nextjs" ]; then
  npx create-next-app@latest --typescript .
elif [ "$STACK_TYPE" = "vue" ]; then
  npm create vue@latest .
else
  echo "Stack não reconhecida, gerando estrutura genérica..."
  touch src/main.${LANGUAGE}
fi

# --- Configuração de pacotes adicionais ----------------
echo "📦 Instalando dependências de estilo e utilitários..."
case "$STYLE_LIB" in
  tailwind)
    $PKG_MANAGER install -D tailwindcss postcss autoprefixer
    npx tailwindcss init -p
    ;;
  chakra)
    $PKG_MANAGER install @chakra-ui/react @emotion/react @emotion/styled framer-motion
    ;;
  material)
    $PKG_MANAGER install @mui/material @emotion/react @emotion/styled
    ;;
esac

# --- Geração de .env e configs -------------------------
echo "🧩 Criando arquivos de configuração..."
cat > .env.example <<EOF
# Ambiente
NODE_ENV=development
PORT=5173

# API
API_URL=https://api.example.com
API_KEY=CHAVE_AQUI
EOF

cat > .gitignore <<EOF
node_modules
dist
.env
.vscode
Dockerfile
EOF

# --- Docker + Traefik (se aplicável) -------------------
if [ "$DEPLOY_TARGET" = "docker-traefik" ]; then
  echo "🐳 Configurando Docker + Traefik..."
  mkdir -p docker/traefik
  cat > docker/Dockerfile.frontend <<'EOF'
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build
EXPOSE 5173
CMD ["npm", "run", "preview"]
EOF

  cat > docker-compose.yml <<'EOF'
version: "3.9"
services:
  traefik:
    image: traefik:v3.1
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
    ports:
      - "80:80"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock

  frontend:
    build:
      context: .
      dockerfile: docker/Dockerfile.frontend
    container_name: frontend-app
    labels:
      - "traefik.http.routers.frontend.rule=Host(`frontend.localhost`)"
    ports:
      - "5173:5173"
EOF
fi

# --- CI/CD Pipeline ------------------------------------
if [ "$CI_PROVIDER" = "github-actions" ]; then
  echo "🚀 Adicionando pipeline GitHub Actions..."
  mkdir -p .github/workflows
  cat > .github/workflows/ci.yml <<'EOF'
name: CI
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci
      - run: npm run build
EOF
fi

# --- Makefile Automatizado -----------------------------
echo "🧠 Criando Makefile..."
cat > Makefile <<EOF
PROJECT=$PROJECT_NAME
PKG_MANAGER=$PKG_MANAGER

setup:
	mkdir -p src/{api,components,context,hooks,pages,services,styles,utils}
	$(PKG_MANAGER) install
	cp .env.example .env

dev:
	$(PKG_MANAGER) run dev

build:
	$(PKG_MANAGER) run build

docker-run:
	docker compose up -d
EOF

# --- Finalização ---------------------------------------
echo "✅ Projeto ${PROJECT_NAME} criado com sucesso!"
echo "➡ Caminho: $(pwd)"
echo "➡ Stack: ${STACK_TYPE} | Linguagem: ${LANGUAGE} | Deploy: ${DEPLOY_TARGET}"