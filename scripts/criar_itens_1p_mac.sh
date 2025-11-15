#!/bin/bash
# Script para criar todos os itens necessários no 1Password
# Execute este script NO MAC (não na VPS)

set -e

echo "🔐 Criando Itens no 1Password"
echo "=============================="
echo ""

# Verificar se 1Password CLI está instalado
if ! command -v op &> /dev/null; then
    echo "❌ 1Password CLI não encontrado"
    echo "   Instale: brew install --cask 1password-cli"
    exit 1
fi

# Verificar autenticação
if ! op account list &> /dev/null; then
    echo "⚠️  Não autenticado. Autenticando..."
    op signin
fi

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VAULT_MACOS="1p_macos"
VAULT_VPS="1p_vps"

echo -e "${BLUE}Criando itens no vault ${VAULT_MACOS} (Mac)...${NC}"

# PostgreSQL Local (Mac)
if op item get "BNI Gestão - PostgreSQL Macos" --vault "$VAULT_MACOS" &> /dev/null; then
    echo -e "${GREEN}  ✅ BNI Gestão - PostgreSQL Macos (já existe)${NC}"
else
    echo -e "${YELLOW}  📝 Criando BNI Gestão - PostgreSQL Macos...${NC}"
    op item create \
      --vault "$VAULT_MACOS" \
      --category "Database" \
      --title "BNI Gestão - PostgreSQL Macos" \
      --field "hostname=localhost" \
      --field "database=bni_gestao" \
      --field "username=postgres" \
      --field "password=postgres" \
      --field "port=5432" && \
    echo -e "${GREEN}  ✅ Criado${NC}"
fi

# Hugging Face Token (Mac)
if op item get "BNI Gestão - Hugging Face Token" --vault "$VAULT_MACOS" &> /dev/null; then
    echo -e "${GREEN}  ✅ BNI Gestão - Hugging Face Token (já existe)${NC}"
else
    echo -e "${YELLOW}  📝 Criando BNI Gestão - Hugging Face Token...${NC}"
    read -p "  Digite o token do Hugging Face (ou Enter para deixar vazio): " HF_TOKEN
    op item create \
      --vault "$VAULT_MACOS" \
      --category "API Credential" \
      --title "BNI Gestão - Hugging Face Token" \
      --field "credential=${HF_TOKEN:-}" \
      --field "dataset=senal88/bni-gestao-imobiliaria" && \
    echo -e "${GREEN}  ✅ Criado${NC}"
fi

echo ""
echo -e "${BLUE}Criando itens no vault ${VAULT_VPS} (VPS)...${NC}"

# PostgreSQL VPS
if op item get "BNI Gestão - PostgreSQL Vps" --vault "$VAULT_VPS" &> /dev/null; then
    echo -e "${GREEN}  ✅ BNI Gestão - PostgreSQL Vps (já existe)${NC}"
else
    echo -e "${YELLOW}  📝 Criando BNI Gestão - PostgreSQL Vps...${NC}"
    POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    op item create \
      --vault "$VAULT_VPS" \
      --category "Database" \
      --title "BNI Gestão - PostgreSQL Vps" \
      --field "hostname=localhost" \
      --field "database=bni_gestao" \
      --field "username=postgres" \
      --field "password=${POSTGRES_PASSWORD}" \
      --field "port=5432" && \
    echo -e "${GREEN}  ✅ Criado${NC}"
    echo -e "${YELLOW}  ⚠️  Senha gerada: ${POSTGRES_PASSWORD}${NC}"
fi

# Hugging Face Token (VPS)
if op item get "BNI Gestão - Hugging Face Token" --vault "$VAULT_VPS" &> /dev/null; then
    echo -e "${GREEN}  ✅ BNI Gestão - Hugging Face Token (já existe)${NC}"
else
    echo -e "${YELLOW}  📝 Criando BNI Gestão - Hugging Face Token...${NC}"
    if [ -z "$HF_TOKEN" ]; then
        read -p "  Digite o token do Hugging Face (ou Enter para deixar vazio): " HF_TOKEN
    fi
    op item create \
      --vault "$VAULT_VPS" \
      --category "API Credential" \
      --title "BNI Gestão - Hugging Face Token" \
      --field "credential=${HF_TOKEN:-}" \
      --field "dataset=senal88/bni-gestao-imobiliaria" && \
    echo -e "${GREEN}  ✅ Criado${NC}"
fi

# SSH Deploy Key (VPS) - Opcional
if op item get "BNI Gestão - SSH Deploy Key" --vault "$VAULT_VPS" &> /dev/null; then
    echo -e "${GREEN}  ✅ BNI Gestão - SSH Deploy Key (já existe)${NC}"
else
    echo -e "${YELLOW}  📝 Criar SSH Deploy Key? (s/N): ${NC}"
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        if [ -f ~/.ssh/id_ed25519_universal ]; then
            SSH_KEY=$(cat ~/.ssh/id_ed25519_universal)
            op item create \
              --vault "$VAULT_VPS" \
              --category "SSH Key" \
              --title "BNI Gestão - SSH Deploy Key" \
              --field "private_key=${SSH_KEY}" \
              --field "host=147.79.81.59" \
              --field "user=root" \
              --field "port=22" && \
            echo -e "${GREEN}  ✅ Criado${NC}"
        else
            echo -e "${YELLOW}  ⚠️  Chave SSH não encontrada em ~/.ssh/id_ed25519_universal${NC}"
        fi
    fi
fi

echo ""
echo -e "${GREEN}✅ Todos os itens criados!${NC}"
echo ""
echo "📋 Resumo:"
echo ""
echo "Vault ${VAULT_MACOS}:"
op item list --vault "$VAULT_MACOS" | grep "BNI Gestão" || echo "  (nenhum item encontrado)"
echo ""
echo "Vault ${VAULT_VPS}:"
op item list --vault "$VAULT_VPS" | grep "BNI Gestão" || echo "  (nenhum item encontrado)"
echo ""
echo "🚀 Próximos passos:"
echo "  1. Na VPS: ./scripts/install_1password_vps.sh"
echo "  2. Na VPS: ./scripts/setup_vps_completo_1p.sh"

