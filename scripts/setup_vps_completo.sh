#!/bin/bash
# Script completo de setup na VPS OVH
# Execute este script DENTRO da VPS (não no Mac!)

set -e

echo "🖥️  SETUP COMPLETO - BNI Gestão Imobiliária na VPS"
echo "=================================================="
echo ""
echo "⚠️  ATENÇÃO: Este script deve ser executado DENTRO da VPS!"
echo "   Conecte-se com: ssh vps"
echo ""

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  Por favor, execute como root ou com sudo"
    exit 1
fi

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Diretório de deploy
DEPLOY_DIR="/opt/bni-gestao-imobiliaria"

echo -e "${BLUE}1. Atualizando sistema...${NC}"
apt update && apt upgrade -y

echo -e "${BLUE}2. Instalando dependências do sistema...${NC}"
apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    docker.io \
    docker-compose \
    postgresql-client \
    curl \
    wget \
    vim \
    openssl

echo -e "${BLUE}3. Configurando Docker...${NC}"
systemctl start docker
systemctl enable docker
usermod -aG docker root

echo -e "${BLUE}4. Criando estrutura de diretórios...${NC}"
mkdir -p "$DEPLOY_DIR"
cd "$DEPLOY_DIR"
mkdir -p data/{raw,processed,schemas}
mkdir -p scripts
mkdir -p logs
mkdir -p reports/ifrs
mkdir -p obsidian/vault_backup

echo -e "${BLUE}5. Clonando repositório...${NC}"
if [ -d "$DEPLOY_DIR/.git" ]; then
    echo "   Repositório já existe, atualizando..."
    cd "$DEPLOY_DIR"
    git pull origin teab || echo "   Aviso: não foi possível atualizar"
else
    git clone https://github.com/senal88/bni-gestao-imobiliaria.git "$DEPLOY_DIR"
fi

echo -e "${BLUE}6. Verificando containers PostgreSQL existentes...${NC}"
POSTGRES_CONTAINERS=$(docker ps -a --format "{{.Names}}" | grep -i postgres || true)

if [ -z "$POSTGRES_CONTAINERS" ]; then
    echo -e "${YELLOW}   Nenhum container PostgreSQL encontrado${NC}"
    echo -e "${YELLOW}   Criando container PostgreSQL dedicado...${NC}"

    # Gerar senha aleatória
    POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

    # Criar docker-compose.prod.yml
    cat > docker-compose.prod.yml << EOF
version: '3.8'

services:
  postgres:
    image: postgres:14-alpine
    container_name: bni_postgres_prod
    environment:
      POSTGRES_DB: bni_gestao
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "127.0.0.1:5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./scripts/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
EOF

    # Salvar senha
    echo "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}" > .env.prod
    chmod 600 .env.prod

    # Iniciar container
    docker-compose -f docker-compose.prod.yml up -d

    echo -e "${GREEN}   ✅ Container PostgreSQL criado e iniciado${NC}"
else
    echo -e "${YELLOW}   Containers PostgreSQL encontrados:${NC}"
    echo "$POSTGRES_CONTAINERS" | while read container; do
        echo "   - $container"
    done
    echo -e "${YELLOW}   Você precisará configurar manualmente o .env${NC}"
fi

echo -e "${BLUE}7. Configurando ambiente Python...${NC}"
cd "$DEPLOY_DIR"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo -e "${BLUE}8. Criando arquivo .env...${NC}"
if [ ! -f .env ]; then
    cat > .env << 'ENVEOF'
# PostgreSQL
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=bni_gestao
POSTGRES_USER=postgres
POSTGRES_PASSWORD=

# Hugging Face
HF_TOKEN=
HF_DATASET_NAME=senal88/bni-gestao-imobiliaria

# Paths
DATA_RAW_PATH=/opt/bni-gestao-imobiliaria/data/raw
DATA_PROCESSED_PATH=/opt/bni-gestao-imobiliaria/data/processed
DATA_SCHEMAS_PATH=/opt/bni-gestao-imobiliaria/data/schemas

# Logging
LOG_LEVEL=INFO
LOG_FILE=/opt/bni-gestao-imobiliaria/logs/bni_gestao.log
ENVEOF

    # Se existe .env.prod, usar a senha de lá
    if [ -f .env.prod ]; then
        POSTGRES_PASSWORD=$(grep POSTGRES_PASSWORD .env.prod | cut -d'=' -f2)
        sed -i "s/POSTGRES_PASSWORD=$/POSTGRES_PASSWORD=${POSTGRES_PASSWORD}/" .env
    fi

    chmod 600 .env
    echo -e "${YELLOW}   ⚠️  Arquivo .env criado. Configure HF_TOKEN manualmente!${NC}"
else
    echo -e "${GREEN}   ✅ Arquivo .env já existe${NC}"
fi

echo -e "${BLUE}9. Inicializando banco de dados...${NC}"
cd "$DEPLOY_DIR"
source venv/bin/activate
export $(cat .env | grep -v '^#' | xargs)
python scripts/init_database.py || echo -e "${YELLOW}   ⚠️  Erro ao inicializar banco. Verifique as configurações.${NC}"

echo ""
echo -e "${GREEN}✅ Setup básico concluído!${NC}"
echo ""
echo -e "${YELLOW}Próximos passos:${NC}"
echo "1. Configure HF_TOKEN no arquivo .env"
echo "2. Importe os dados: cd $DEPLOY_DIR && source venv/bin/activate && python scripts/import_propriedades.py"
echo "3. Configure crontab para sincronização automática (opcional)"
echo ""
echo -e "${BLUE}Para verificar:${NC}"
echo "  docker ps | grep postgres"
echo "  cd $DEPLOY_DIR && source venv/bin/activate && python scripts/init_database.py --validate-only"

