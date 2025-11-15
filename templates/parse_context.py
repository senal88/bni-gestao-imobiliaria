
import re
import os
import stat

def parse_markdown(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    params = {}

    # Extrai variáveis simples (ex: **PROJECT_NAME:**)
    simple_vars = re.findall(r'\*\*([A-Z_]+):\*\*\s*`([^`]+)`', content)
    for key, value in simple_vars:
        params[key] = value

    # Extrai variáveis de tabelas
    table_vars = re.findall(r'\|\s+\*\*([A-Z_]+)\*\*\s+\|\s+`([^`]+)`', content)
    for key, value in table_vars:
        params[key] = value.split(' / ')[0] # Pega a primeira opção

    return params

def generate_script(params):
    script_content = f"""#!/usr/bin/env bash
set -e

# --- Parâmetros extraídos do Python ---
PROJECT_NAME="{params.get('PROJECT_NAME', 'default-project')}"
STACK_TYPE="{params.get('STACK_TYPE', 'react')}"
LANGUAGE="{params.get('LANGUAGE', 'ts')}"
PKG_MANAGER="{params.get('PKG_MANAGER', 'npm')}"
STYLE_LIB="{params.get('STYLE_LIB', 'none')}"
DEPLOY_TARGET="{params.get('DEPLOY_TARGET', 'none')}"
CI_PROVIDER="{params.get('CI_PROVIDER', 'none')}"

# --- Validação ---
if [ -z "$PROJECT_NAME" ]; then
  echo "❌ ERRO: PROJECT_NAME não pôde ser extraído."
  exit 1
fi

echo "--- Parâmetros ---"
echo "Nome do Projeto: $PROJECT_NAME"
echo "Stack: $STACK_TYPE"
echo "Linguagem: $LANGUAGE"
echo "Gerenciador de Pacotes: $PKG_MANAGER"
echo "Estilo: $STYLE_LIB"
echo "Deploy: $DEPLOY_TARGET"
echo "CI: $CI_PROVIDER"
echo "--------------------"

# --- Criação da estrutura ---
echo "📁 Criando estrutura do projeto: $PROJECT_NAME ..."
mkdir -p $PROJECT_NAME
cd $PROJECT_NAME
mkdir -p src/{{api,components,context,hooks,pages,services,styles,utils}} public docker .github/workflows .vscode

# --- Inicialização do projeto ---
echo "⚙️  Inicializando projeto $STACK_TYPE ($LANGUAGE)..."
if [ "$STACK_TYPE" = "react" ] && [ "$LANGUAGE" = "ts" ]; then
  $PKG_MANAGER create vite@latest . -- --template react-ts
elif [ "$STACK_TYPE" = "nextjs" ]; then
  $PKG_MANAGER create next-app@latest . --typescript --eslint --tailwind --src-dir --app --import-alias "@/*"
else
  echo "Stack não configurada para inicialização automática, criando estrutura genérica..."
  touch src/main.$LANGUAGE
fi

# --- Instalação de dependências de estilo ---
if [ "$STYLE_LIB" = "tailwind" ] && [ "$STACK_TYPE" != "nextjs" ]; then
    echo "📦 Instalando TailwindCSS..."
    $PKG_MANAGER add -D tailwindcss postcss autoprefixer
    npx tailwindcss init -p
fi

# --- Criação de arquivos de configuração ---
echo "🧩 Criando arquivos de configuração..."

# .gitignore
cat > .gitignore <<EOF
# Dependencies
node_modules

# Build output
dist
.next

# Logs
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Environment variables
.env
.env.local
EOF

# docker-compose.yml
if [ "$DEPLOY_TARGET" = "docker-traefik" ]; then
  echo "🐳 Configurando Docker + Traefik..."
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
    build: .
    container_name: ${PROJECT_NAME}
    labels:
      - "traefik.http.routers.frontend.rule=Host(`${PROJECT_NAME}.localhost`)"
EOF
fi

# --- Finalização ---
echo "✅ Projeto ${PROJECT_NAME} criado com sucesso!"
echo "➡ Caminho: $(pwd)"
"""
    with open('generate-repo.sh', 'w', encoding='utf-8') as f:
        f.write(script_content)

    # Torna o script executável
    st = os.stat('generate-repo.sh')
    os.chmod('generate-repo.sh', st.st_mode | stat.S_IEXEC)


if __name__ == "__main__":
    params = parse_markdown('frontend-project-context.md')
    generate_script(params)
    print("Script 'generate-repo.sh' criado com sucesso.")

