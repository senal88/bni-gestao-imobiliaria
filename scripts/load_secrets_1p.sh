#!/bin/bash
# Script para carregar secrets do 1Password para arquivo .env
# Funciona tanto no Mac quanto na VPS

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Detectar ambiente
if [ -f "/.dockerenv" ] || [ -f "/proc/1/cgroup" ] && grep -q docker /proc/1/cgroup; then
    ENV="docker"
elif [ "$(uname)" == "Darwin" ]; then
    ENV="macos"
    VAULT="1p_macos"
elif [ -f "/etc/os-release" ]; then
    ENV="vps"
    VAULT="1p_vps"
else
    ENV="unknown"
    VAULT="default importado"
fi

echo "🔐 Carregando secrets do 1Password..."
echo "   Ambiente detectado: $ENV"
echo "   Vault: $VAULT"
echo ""

# Verificar se 1Password CLI está instalado
if ! command -v op &> /dev/null; then
    echo -e "${RED}❌ 1Password CLI não encontrado${NC}"
    echo "   Instale: brew install --cask 1password-cli (Mac) ou siga docs/INTEGRACAO_1PASSWORD.md"
    exit 1
fi

# Verificar autenticação
if ! op account list &> /dev/null; then
    echo -e "${YELLOW}⚠️  Não autenticado no 1Password. Autenticando...${NC}"
    op signin
fi

# Diretório do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

# Função para obter valor do 1Password com fallback
get_secret() {
    local item_name="$1"
    local field_name="$2"
    local default_value="${3:-}"

    local value
    value=$(op item get "$item_name" --vault "$VAULT" --fields "$field_name" 2>/dev/null || echo "")

    if [ -z "$value" ] && [ -n "$default_value" ]; then
        echo "$default_value"
    else
        echo "$value"
    fi
}

echo "📥 Obtendo secrets do 1Password..."

# PostgreSQL
POSTGRES_HOST=$(get_secret "BNI Gestão - PostgreSQL ${ENV^}" "hostname" "localhost")
POSTGRES_PORT=$(get_secret "BNI Gestão - PostgreSQL ${ENV^}" "port" "5432")
POSTGRES_DB=$(get_secret "BNI Gestão - PostgreSQL ${ENV^}" "database" "bni_gestao")
POSTGRES_USER=$(get_secret "BNI Gestão - PostgreSQL ${ENV^}" "username" "postgres")
POSTGRES_PASSWORD=$(get_secret "BNI Gestão - PostgreSQL ${ENV^}" "password" "")

# Hugging Face
HF_TOKEN=$(get_secret "BNI Gestão - Hugging Face Token" "credential" "")
HF_DATASET_NAME=$(get_secret "BNI Gestão - Hugging Face Token" "dataset" "senal88/bni-gestao-imobiliaria")

# GitHub Token
if [ "$ENV" = "macos" ]; then
    GH_TOKEN=$(get_secret "GH_TOKEN" "token" "")
else
    GH_TOKEN=$(get_secret "GitHub Personal Access Token" "token" "")
fi

# Paths (diferentes para Mac e VPS)
if [ "$ENV" = "macos" ]; then
    DATA_RAW_PATH="./data/raw"
    DATA_PROCESSED_PATH="./data/processed"
    DATA_SCHEMAS_PATH="./data/schemas"
    LOG_FILE="./logs/bni_gestao.log"
else
    DATA_RAW_PATH="/opt/bni-gestao-imobiliaria/data/raw"
    DATA_PROCESSED_PATH="/opt/bni-gestao-imobiliaria/data/processed"
    DATA_SCHEMAS_PATH="/opt/bni-gestao-imobiliaria/data/schemas"
    LOG_FILE="/opt/bni-gestao-imobiliaria/logs/bni_gestao.log"
fi

# Verificar se conseguiu obter secrets essenciais
if [ -z "$POSTGRES_PASSWORD" ]; then
    echo -e "${YELLOW}⚠️  Senha do PostgreSQL não encontrada no 1Password${NC}"
    echo "   Criando item no 1Password ou usando valor padrão..."
    if [ "$ENV" = "macos" ]; then
        POSTGRES_PASSWORD="postgres"
    else
        echo -e "${RED}❌ Senha do PostgreSQL é obrigatória na VPS${NC}"
        exit 1
    fi
fi

# Criar arquivo .env
echo "📝 Criando arquivo .env..."

cat > .env << EOF
# ============================================
# BNI Gestão Imobiliária - Configuração
# Gerado automaticamente do 1Password em $(date)
# ============================================

# PostgreSQL Database
POSTGRES_HOST=${POSTGRES_HOST}
POSTGRES_PORT=${POSTGRES_PORT}
POSTGRES_DB=${POSTGRES_DB}
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

# Hugging Face
HF_TOKEN=${HF_TOKEN}
HF_DATASET_NAME=${HF_DATASET_NAME}
HF_DATASET_REVISION=main

# GitHub
GH_TOKEN=${GH_TOKEN}

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
API_DEBUG=False

# Obsidian Integration
OBSIDIAN_VAULT_PATH=./obsidian/vault_backup
OBSIDIAN_TEMPLATE_PATH=./obsidian/templates

# Data Paths
DATA_RAW_PATH=${DATA_RAW_PATH}
DATA_PROCESSED_PATH=${DATA_PROCESSED_PATH}
DATA_SCHEMAS_PATH=${DATA_SCHEMAS_PATH}

# Logging
LOG_LEVEL=INFO
LOG_FILE=${LOG_FILE}

# IFRS Reports
IFRS_REPORTS_PATH=./reports/ifrs
IFRS_REPORTS_FORMAT=pdf

# Security
SECRET_KEY=$(openssl rand -hex 32)
ALLOWED_HOSTS=localhost,127.0.0.1
EOF

chmod 600 .env

echo -e "${GREEN}✅ Arquivo .env criado com sucesso!${NC}"
echo ""
echo "📋 Secrets carregados:"
echo "   PostgreSQL: ${POSTGRES_USER}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"
echo "   Hugging Face: ${HF_DATASET_NAME}"
if [ -z "$HF_TOKEN" ]; then
    echo -e "${YELLOW}   ⚠️  HF_TOKEN não encontrado - configure manualmente se necessário${NC}"
fi
if [ -n "$GH_TOKEN" ]; then
    echo "   GitHub: ✅ Token configurado"
else
    echo -e "${YELLOW}   ⚠️  GH_TOKEN não encontrado - configure manualmente se necessário${NC}"
fi

