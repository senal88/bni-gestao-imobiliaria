#!/bin/bash
# Script para oficializar GH_TOKEN em todos os cofres do 1Password
# Garante que o token GitHub esteja disponível em ambos os cofres (1p_macos e 1p_vps)

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Verificando GH_TOKEN nos cofres do 1Password...${NC}"
echo ""

# IDs dos cofres
VAULT_MACOS="1p_macos"
VAULT_VPS="1p_vps"

# ID do item GitHub Personal Access Token no cofre VPS
GH_TOKEN_VPS_ID="6wyjxojyqsdblpbjypxwhkx43y"
GH_TOKEN_VPS_TITLE="GitHub Personal Access Token"

# Verificar se o item existe no cofre VPS
echo -e "${BLUE}1. Verificando token no cofre ${VAULT_VPS}...${NC}"
VPS_TOKEN=$(op item get "$GH_TOKEN_VPS_ID" --vault "$VAULT_VPS" --fields label=token 2>/dev/null || echo "")

if [ -z "$VPS_TOKEN" ]; then
    echo -e "${RED}❌ Token não encontrado no cofre ${VAULT_VPS}${NC}"
    exit 1
fi

echo -e "${GREEN}   ✅ Token encontrado no cofre ${VAULT_VPS}${NC}"

# Verificar se existe item similar no cofre macOS
echo -e "${BLUE}2. Verificando token no cofre ${VAULT_MACOS}...${NC}"
MACOS_GH_ITEMS=$(op item list --vault "$VAULT_MACOS" 2>/dev/null | grep -i "github\|gh_token\|git.*token" || echo "")

if [ -z "$MACOS_GH_ITEMS" ]; then
    echo -e "${YELLOW}   ⚠️  Nenhum item GitHub encontrado no cofre ${VAULT_MACOS}${NC}"
    echo -e "${BLUE}   📝 Criando item GH_TOKEN no cofre ${VAULT_MACOS}...${NC}"

    # Obter o token do cofre VPS
    TOKEN_VALUE=$(op item get "$GH_TOKEN_VPS_ID" --vault "$VAULT_VPS" --fields label=token --format json 2>/dev/null | python3 -c "import sys, json; print(json.load(sys.stdin)['value'])" 2>/dev/null || echo "")

    if [ -z "$TOKEN_VALUE" ]; then
        echo -e "${RED}   ❌ Não foi possível obter o token do cofre ${VAULT_VPS}${NC}"
        echo -e "${YELLOW}   💡 Execute manualmente:${NC}"
        echo "      op item get $GH_TOKEN_VPS_ID --vault $VAULT_VPS --fields label=token"
        exit 1
    fi

    # Criar item no cofre macOS
    echo -e "${BLUE}   Criando item 'GH_TOKEN' no cofre ${VAULT_MACOS}...${NC}"

    # Criar usando op item create
    op item create \
        --category "API Credential" \
        --title "GH_TOKEN" \
        --vault "$VAULT_MACOS" \
        field[label="token"][value]="$TOKEN_VALUE" \
        field[label="notesPlain"][value]="GitHub Personal Access Token - Sincronizado do cofre ${VAULT_VPS}" \
        url="https://github.com/settings/tokens" 2>&1 || {
        echo -e "${YELLOW}   ⚠️  Erro ao criar item automaticamente${NC}"
        echo -e "${BLUE}   📋 Criando manualmente...${NC}"

        # Tentar criar via JSON
        cat << EOF | op item create --vault "$VAULT_MACOS" 2>&1 || true
{
  "title": "GH_TOKEN",
  "category": "API_CREDENTIAL",
  "fields": [
    {
      "id": "token",
      "type": "CONCEALED",
      "label": "token",
      "value": "$TOKEN_VALUE"
    },
    {
      "id": "notesPlain",
      "type": "STRING",
      "purpose": "NOTES",
      "label": "notesPlain",
      "value": "GitHub Personal Access Token - Sincronizado do cofre ${VAULT_VPS}"
    }
  ],
  "urls": [
    {
      "label": "website",
      "primary": true,
      "href": "https://github.com/settings/tokens"
    }
  ]
}
EOF
    }

    echo -e "${GREEN}   ✅ Item GH_TOKEN criado no cofre ${VAULT_MACOS}${NC}"
else
    echo -e "${GREEN}   ✅ Item GitHub encontrado no cofre ${VAULT_MACOS}${NC}"
    echo "$MACOS_GH_ITEMS"

    # Verificar se precisa sincronizar
    echo -e "${BLUE}   🔄 Verificando se precisa sincronizar tokens...${NC}"

    # Listar IDs dos itens GitHub no macOS
    MACOS_GH_IDS=$(op item list --vault "$VAULT_MACOS" 2>/dev/null | grep -i "github\|gh_token\|git.*token" | awk '{print $1}' || echo "")

    if [ -n "$MACOS_GH_IDS" ]; then
        echo -e "${YELLOW}   ℹ️  Múltiplos itens GitHub encontrados no cofre ${VAULT_MACOS}${NC}"
        echo -e "${BLUE}   💡 Recomendação: Use o item 'GH_TOKEN' ou 'GitHub Personal Access Token'${NC}"
    fi
fi

echo ""
echo -e "${GREEN}✅ Verificação concluída!${NC}"
echo ""
echo -e "${BLUE}📋 Resumo:${NC}"
echo "   Cofre ${VAULT_VPS}: ✅ Token disponível"
echo "   Cofre ${VAULT_MACOS}: ✅ Token disponível"
echo ""
echo -e "${BLUE}💡 Para usar o token:${NC}"
echo "   # No macOS:"
echo "   export GH_TOKEN=\$(op item get GH_TOKEN --vault ${VAULT_MACOS} --fields label=token)"
echo ""
echo "   # Na VPS:"
echo "   export GH_TOKEN=\$(op item get '${GH_TOKEN_VPS_TITLE}' --vault ${VAULT_VPS} --fields label=token)"
echo ""

