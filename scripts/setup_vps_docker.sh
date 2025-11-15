#!/bin/bash
# Script de setup completo na VPS usando Docker Compose
# Execute este script DENTRO da VPS (não no Mac!)

set -e

echo "🖥️  SETUP COMPLETO COM DOCKER - BNI Gestão Imobiliária na VPS"
echo "=============================================================="
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
RED='\033[0;31m'
NC='\033[0m' # No Color

# Diretório de deploy
DEPLOY_DIR="/opt/bni-gestao-imobiliaria"

echo -e "${BLUE}1. Verificando Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}   Docker não encontrado. Instalando...${NC}"
    apt update
    apt install -y docker.io docker-compose
    systemctl start docker
    systemctl enable docker
else
    echo -e "${GREEN}   ✅ Docker instalado: $(docker --version)${NC}"
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}   Docker Compose não encontrado. Instalando...${NC}"
    apt install -y docker-compose
else
    echo -e "${GREEN}   ✅ Docker Compose disponível${NC}"
fi

echo -e "${BLUE}2. Criando estrutura de diretórios...${NC}"
mkdir -p "$DEPLOY_DIR"
cd "$DEPLOY_DIR"
mkdir -p data/{raw,processed,schemas}
mkdir -p scripts
mkdir -p logs
mkdir -p reports/ifrs
mkdir -p obsidian/vault_backup

echo -e "${BLUE}3. Clonando/Atualizando repositório...${NC}"
if [ -d "$DEPLOY_DIR/.git" ]; then
    echo "   Repositório já existe, atualizando..."
    cd "$DEPLOY_DIR"
    git pull origin teab || echo "   Aviso: não foi possível atualizar"
else
    git clone https://github.com/senal88/bni-gestao-imobiliaria.git "$DEPLOY_DIR"
fi

echo -e "${BLUE}4. Verificando containers PostgreSQL existentes...${NC}"
POSTGRES_CONTAINERS=$(docker ps -a --format "{{.Names}}" | grep -i postgres || true)

if [ -z "$POSTGRES_CONTAINERS" ]; then
    echo -e "${YELLOW}   Nenhum container PostgreSQL encontrado${NC}"
    USE_EXISTING=false
else
    echo -e "${YELLOW}   Containers PostgreSQL encontrados:${NC}"
    echo "$POSTGRES_CONTAINERS" | while read container; do
        echo "   - $container"
    done
    echo ""
    read -p "   Usar container existente? (s/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        USE_EXISTING=true
        echo -e "${YELLOW}   Qual container usar? Cole o nome:${NC}"
        read -r CONTAINER_NAME
    else
        USE_EXISTING=false
    fi
fi

if [ "$USE_EXISTING" = false ]; then
    echo -e "${BLUE}5. Configurando Docker Compose para PostgreSQL...${NC}"

    # Gerar senha aleatória
    POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

    # Copiar docker-compose.prod.yml
    if [ -f docker-compose.prod.yml ]; then
        echo -e "${GREEN}   ✅ docker-compose.prod.yml já existe${NC}"
    else
        echo -e "${YELLOW}   ⚠️  docker-compose.prod.yml não encontrado no repositório${NC}"
        echo "   Criando docker-compose.prod.yml básico..."
        # O arquivo será criado pelo git clone acima
    fi

    # Criar .env.prod com senha
    cat > .env.prod << EOF
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=bni_gestao
POSTGRES_USER=postgres
PGADMIN_EMAIL=admin@bni.local
PGADMIN_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-12)
EOF
    chmod 600 .env.prod

    echo -e "${GREEN}   ✅ Arquivo .env.prod criado com senhas geradas${NC}"
    echo -e "${YELLOW}   ⚠️  IMPORTANTE: Anote a senha do PostgreSQL: ${POSTGRES_PASSWORD}${NC}"

    echo -e "${BLUE}6. Iniciando containers Docker...${NC}"
    docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d

    echo -e "${GREEN}   ✅ Containers iniciados${NC}"
    sleep 5

    # Verificar status
    docker ps | grep bni_

    POSTGRES_HOST="localhost"
    POSTGRES_PORT="5432"
    POSTGRES_DB="bni_gestao"
    POSTGRES_USER="postgres"
    POSTGRES_PASSWORD="${POSTGRES_PASSWORD}"
else
    echo -e "${BLUE}5. Configurando para usar container existente...${NC}"
    echo -e "${YELLOW}   Container: ${CONTAINER_NAME}${NC}"

    # Testar conexão
    echo -e "${BLUE}   Testando conexão...${NC}"
    docker exec "$CONTAINER_NAME" psql -U postgres -c "SELECT 1;" &> /dev/null || {
        echo -e "${RED}   ❌ Erro ao conectar ao container${NC}"
        exit 1
    }

    # Criar banco se não existir
    docker exec "$CONTAINER_NAME" psql -U postgres -c "CREATE DATABASE bni_gestao;" 2>/dev/null || echo "   Banco já existe"

    POSTGRES_HOST="localhost"
    POSTGRES_PORT="5432"
    POSTGRES_DB="bni_gestao"
    POSTGRES_USER="postgres"
    echo -e "${YELLOW}   ⚠️  Você precisará configurar POSTGRES_PASSWORD manualmente no .env${NC}"
    POSTGRES_PASSWORD=""
fi

echo -e "${BLUE}7. Configurando ambiente Python...${NC}"
cd "$DEPLOY_DIR"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo -e "${BLUE}8. Criando arquivo .env...${NC}"
if [ ! -f .env ]; then
    cat > .env << EOF
# PostgreSQL
POSTGRES_HOST=${POSTGRES_HOST}
POSTGRES_PORT=${POSTGRES_PORT}
POSTGRES_DB=${POSTGRES_DB}
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

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
EOF
    chmod 600 .env
    echo -e "${GREEN}   ✅ Arquivo .env criado${NC}"
    echo -e "${YELLOW}   ⚠️  Configure HF_TOKEN manualmente no arquivo .env${NC}"
else
    echo -e "${GREEN}   ✅ Arquivo .env já existe${NC}"
fi

echo -e "${BLUE}9. Inicializando banco de dados...${NC}"
cd "$DEPLOY_DIR"
source venv/bin/activate
export $(cat .env | grep -v '^#' | xargs)

# Aguardar PostgreSQL estar pronto
if [ "$USE_EXISTING" = false ]; then
    echo "   Aguardando PostgreSQL estar pronto..."
    for i in {1..30}; do
        if docker exec bni_postgres_prod pg_isready -U postgres &> /dev/null; then
            echo -e "${GREEN}   ✅ PostgreSQL pronto${NC}"
            break
        fi
        sleep 1
    done
fi

python scripts/init_database.py || {
    echo -e "${YELLOW}   ⚠️  Erro ao inicializar banco. Verifique as configurações.${NC}"
    echo "   Você pode tentar manualmente depois com:"
    echo "   cd $DEPLOY_DIR && source venv/bin/activate && python scripts/init_database.py"
}

echo ""
echo -e "${GREEN}✅ Setup básico concluído!${NC}"
echo ""
echo -e "${YELLOW}Próximos passos:${NC}"
echo "1. Configure HF_TOKEN no arquivo .env:"
echo "   nano $DEPLOY_DIR/.env"
echo ""
echo "2. Importe os dados:"
echo "   cd $DEPLOY_DIR"
echo "   source venv/bin/activate"
echo "   python scripts/import_propriedades.py"
echo ""
echo "3. Verifique os containers:"
echo "   docker ps | grep bni_"
echo ""
echo "4. Acesse pgAdmin (se configurado):"
echo "   http://localhost:5050"
echo ""
echo -e "${BLUE}Comandos úteis:${NC}"
echo "  docker-compose -f docker-compose.prod.yml ps"
echo "  docker-compose -f docker-compose.prod.yml logs -f"
echo "  docker-compose -f docker-compose.prod.yml restart"

