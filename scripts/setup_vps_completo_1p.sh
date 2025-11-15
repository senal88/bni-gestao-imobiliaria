#!/bin/bash
# Setup completo na VPS usando 1Password para secrets
# Execute este script DENTRO da VPS após instalar 1Password CLI

set -e

echo "🖥️  SETUP COMPLETO COM 1PASSWORD - BNI Gestão Imobiliária na VPS"
echo "================================================================="
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
NC='\033[0m'

# Diretório de deploy
DEPLOY_DIR="/opt/bni-gestao-imobiliaria"

# Verificar 1Password CLI
if ! command -v op &> /dev/null; then
    echo -e "${RED}❌ 1Password CLI não encontrado${NC}"
    echo "   Execute primeiro: ./scripts/install_1password_vps.sh"
    exit 1
fi

# Verificar autenticação
if ! op account list &> /dev/null; then
    echo -e "${RED}❌ Não autenticado no 1Password${NC}"
    echo "   Execute: op signin"
    exit 1
fi

# Verificar vault
if ! op vault list | grep -q "1p_vps"; then
    echo -e "${RED}❌ Vault '1p_vps' não encontrado${NC}"
    exit 1
fi

echo -e "${BLUE}1. Criando estrutura de diretórios...${NC}"
mkdir -p "$DEPLOY_DIR"
cd "$DEPLOY_DIR"
mkdir -p data/{raw,processed,schemas}
mkdir -p scripts
mkdir -p logs
mkdir -p reports/ifrs
mkdir -p obsidian/vault_backup

echo -e "${BLUE}2. Clonando/Atualizando repositório...${NC}"
if [ -d "$DEPLOY_DIR/.git" ]; then
    echo "   Repositório já existe, atualizando..."
    cd "$DEPLOY_DIR"
    git pull origin teab || echo "   Aviso: não foi possível atualizar"
else
    git clone https://github.com/senal88/bni-gestao-imobiliaria.git "$DEPLOY_DIR"
fi

echo -e "${BLUE}3. Verificando e criando itens no 1Password...${NC}"

# Função para criar item se não existir
create_item_if_not_exists() {
    local item_name="$1"
    local category="$2"
    local fields="$3"

    if op item get "$item_name" --vault "1p_vps" &> /dev/null; then
        echo -e "${GREEN}   ✅ Item '$item_name' já existe${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Criando item '$item_name'...${NC}"
        eval "op item create --vault '1p_vps' --category '$category' --title '$item_name' $fields" || {
            echo -e "${RED}   ❌ Erro ao criar item. Crie manualmente no 1Password${NC}"
        }
    fi
}

# Criar item PostgreSQL se não existir
POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
create_item_if_not_exists "BNI Gestão - PostgreSQL Vps" "Database" \
  "--field 'hostname=localhost' --field 'database=bni_gestao' --field 'username=postgres' --field 'password=${POSTGRES_PASSWORD}' --field 'port=5432'"

# Criar item Hugging Face se não existir (sem token, precisa preencher depois)
create_item_if_not_exists "BNI Gestão - Hugging Face Token" "API Credential" \
  "--field 'credential=' --field 'dataset=senal88/bni-gestao-imobiliaria'"

echo -e "${BLUE}4. Carregando secrets do 1Password...${NC}"
cd "$DEPLOY_DIR"
./scripts/load_secrets_1p.sh

echo -e "${BLUE}5. Verificando Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo "   Instalando Docker..."
    apt update
    apt install -y docker.io docker-compose
    systemctl start docker
    systemctl enable docker
fi

echo -e "${BLUE}6. Verificando containers PostgreSQL...${NC}"
POSTGRES_CONTAINERS=$(docker ps -a --format "{{.Names}}" | grep -i postgres || true)

if [ -z "$POSTGRES_CONTAINERS" ]; then
    echo -e "${YELLOW}   Nenhum container PostgreSQL encontrado${NC}"
    USE_EXISTING=false
else
    echo -e "${YELLOW}   Containers PostgreSQL encontrados:${NC}"
    echo "$POSTGRES_CONTAINERS"
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
    echo -e "${BLUE}7. Configurando Docker Compose...${NC}"

    # Obter senha do 1Password
    POSTGRES_PASSWORD=$(op item get "BNI Gestão - PostgreSQL Vps" --vault "1p_vps" --fields "password" 2>/dev/null || echo "")

    if [ -z "$POSTGRES_PASSWORD" ]; then
        echo -e "${RED}   ❌ Senha do PostgreSQL não encontrada no 1Password${NC}"
        exit 1
    fi

    # Criar .env.prod
    cat > .env.prod << EOF
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=bni_gestao
POSTGRES_USER=postgres
PGADMIN_EMAIL=admin@bni.local
PGADMIN_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-12)
EOF
    chmod 600 .env.prod

    echo -e "${BLUE}8. Iniciando containers Docker...${NC}"
    docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d

    echo -e "${GREEN}   ✅ Containers iniciados${NC}"
    sleep 5
    docker ps | grep bni_
else
    echo -e "${BLUE}7. Configurando para usar container existente...${NC}"
    docker exec "$CONTAINER_NAME" psql -U postgres -c "CREATE DATABASE bni_gestao;" 2>/dev/null || echo "   Banco já existe"
fi

echo -e "${BLUE}9. Configurando ambiente Python...${NC}"
cd "$DEPLOY_DIR"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo -e "${BLUE}10. Inicializando banco de dados...${NC}"
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
}

echo ""
echo -e "${GREEN}✅ Setup completo concluído!${NC}"
echo ""
echo -e "${YELLOW}Próximos passos:${NC}"
echo "1. Configure HF_TOKEN no 1Password (se ainda não configurou):"
echo "   op item edit 'BNI Gestão - Hugging Face Token' --vault '1p_vps' credential='seu_token'"
echo ""
echo "2. Recarregue secrets:"
echo "   cd $DEPLOY_DIR"
echo "   ./scripts/load_secrets_1p.sh"
echo ""
echo "3. Importe os dados:"
echo "   cd $DEPLOY_DIR"
echo "   source venv/bin/activate"
echo "   python scripts/import_propriedades.py"
echo ""
echo -e "${BLUE}Comandos úteis:${NC}"
echo "  docker ps | grep bni_"
echo "  docker-compose -f docker-compose.prod.yml ps"
echo "  ./scripts/load_secrets_1p.sh  # Recarregar secrets"

