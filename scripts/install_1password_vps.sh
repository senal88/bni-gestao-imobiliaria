#!/bin/bash
# Script para instalar e configurar 1Password CLI na VPS
# Execute este script DENTRO da VPS

set -e

echo "🔐 Instalação e Configuração do 1Password CLI na VPS"
echo "====================================================="
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

echo -e "${BLUE}1. Instalando 1Password CLI...${NC}"

# Verificar se já está instalado
if command -v op &> /dev/null; then
    echo -e "${GREEN}   ✅ 1Password CLI já instalado: $(op --version)${NC}"
else
    echo "   Instalando 1Password CLI..."

    # Detectar arquitetura
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        ARCH="amd64"
    elif [ "$ARCH" = "aarch64" ]; then
        ARCH="arm64"
    else
        ARCH="amd64"
    fi

    # Adicionar repositório
    curl -sSf https://downloads.1password.com/linux/keys/1password.asc | \
      gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

    echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/${ARCH} stable main" | \
      tee /etc/apt/sources.list.d/1password.list

    # Instalar
    apt update
    apt install -y 1password-cli

    echo -e "${GREEN}   ✅ 1Password CLI instalado${NC}"
fi

echo ""
echo -e "${BLUE}2. Configurando autenticação...${NC}"

# Verificar se já está autenticado
if op account list &> /dev/null; then
    echo -e "${GREEN}   ✅ Já autenticado no 1Password${NC}"
    op account list
else
    echo -e "${YELLOW}   ⚠️  Autenticação necessária${NC}"
    echo ""
    echo "   Para autenticar, você precisa:"
    echo "   1. Ter o 1Password app instalado no seu Mac"
    echo "   2. Ter o vault '1p_vps' configurado"
    echo "   3. Executar no Mac: op signin --account <sua-conta>"
    echo ""
    echo "   Ou use autenticação manual:"
    echo "   op signin"
    echo ""
    read -p "   Pressione Enter após autenticar manualmente..."
fi

echo ""
echo -e "${BLUE}3. Verificando acesso ao vault 1p_vps...${NC}"

if op vault list | grep -q "1p_vps"; then
    echo -e "${GREEN}   ✅ Vault '1p_vps' encontrado${NC}"
    op vault list
else
    echo -e "${RED}   ❌ Vault '1p_vps' não encontrado${NC}"
    echo "   Vaults disponíveis:"
    op vault list
    echo ""
    echo "   Configure o vault '1p_vps' no 1Password ou ajuste o script"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Instalação concluída!${NC}"
echo ""
echo "📋 Próximos passos:"
echo "   1. Criar itens no vault '1p_vps':"
echo "      - BNI Gestão - PostgreSQL Vps"
echo "      - BNI Gestão - Hugging Face Token"
echo "   2. Usar script de carregamento:"
echo "      cd /opt/bni-gestao-imobiliaria"
echo "      ./scripts/load_secrets_1p.sh"

