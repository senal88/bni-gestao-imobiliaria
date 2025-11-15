#!/bin/bash
# Script de setup inicial do VPS para deploy do BNI Gestão Imobiliária

set -e

echo "🚀 Configurando VPS para BNI Gestão Imobiliária"
echo "================================================"

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  Por favor, execute como root ou com sudo"
    exit 1
fi

# Diretório de deploy
DEPLOY_DIR="/opt/bni-gestao-imobiliaria"

echo -e "${YELLOW}1. Criando diretório de deploy...${NC}"
mkdir -p "$DEPLOY_DIR"
cd "$DEPLOY_DIR"

echo -e "${YELLOW}2. Instalando dependências do sistema...${NC}"
apt update
apt install -y python3 python3-pip git docker.io docker-compose

echo -e "${YELLOW}3. Verificando containers PostgreSQL existentes...${NC}"
POSTGRES_CONTAINERS=$(docker ps -a --format "{{.Names}}" | grep -i postgres || true)

if [ -z "$POSTGRES_CONTAINERS" ]; then
    echo "⚠️  Nenhum container PostgreSQL encontrado"
    echo "   Você precisará criar um ou usar um existente"
else
    echo "📦 Containers PostgreSQL encontrados:"
    echo "$POSTGRES_CONTAINERS"
fi

echo -e "${YELLOW}4. Configurando permissões...${NC}"
chmod 755 "$DEPLOY_DIR"

echo -e "${YELLOW}5. Criando estrutura de diretórios...${NC}"
mkdir -p "$DEPLOY_DIR/data/raw"
mkdir -p "$DEPLOY_DIR/data/processed"
mkdir -p "$DEPLOY_DIR/data/schemas"
mkdir -p "$DEPLOY_DIR/logs"
mkdir -p "$DEPLOY_DIR/reports/ifrs"

echo -e "${GREEN}✅ Setup básico concluído!${NC}"
echo ""
echo "Próximos passos:"
echo "1. Clone o repositório: git clone https://github.com/senal88/bni-gestao-imobiliaria.git $DEPLOY_DIR"
echo "2. Configure as variáveis de ambiente em $DEPLOY_DIR/.env"
echo "3. Configure os secrets no GitHub"
echo "4. Teste o deploy manualmente"

