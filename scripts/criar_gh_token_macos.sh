#!/bin/bash
# Script para criar item GH_TOKEN no cofre 1p_macos baseado no token do cofre 1p_vps

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

VAULT_VPS="1p_vps"
VAULT_MACOS="1p_macos"
GH_TOKEN_VPS_ID="6wyjxojyqsdblpbjypxwhkx43y"
ITEM_TITLE="GH_TOKEN"

echo -e "${BLUE}🔍 Verificando se GH_TOKEN já existe no cofre ${VAULT_MACOS}...${NC}"

# Verificar se já existe
EXISTING=$(op item list --vault "$VAULT_MACOS" 2>/dev/null | grep -i "^[a-z0-9]*.*${ITEM_TITLE}" | awk '{print $1}' || echo "")

if [ -n "$EXISTING" ]; then
    echo -e "${GREEN}✅ Item ${ITEM_TITLE} já existe no cofre ${VAULT_MACOS}${NC}"
    echo -e "${BLUE}   ID: ${EXISTING}${NC}"
    exit 0
fi

echo -e "${YELLOW}⚠️  Item ${ITEM_TITLE} não encontrado no cofre ${VAULT_MACOS}${NC}"
echo -e "${BLUE}📥 Obtendo token do cofre ${VAULT_VPS}...${NC}"

# Obter token do cofre VPS
TOKEN_VALUE=$(op item get "$GH_TOKEN_VPS_ID" --vault "$VAULT_VPS" --fields label=token --format json 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if isinstance(data, dict) and 'value' in data:
        print(data['value'])
    elif isinstance(data, list) and len(data) > 0:
        print(data[0].get('value', ''))
    else:
        print('')
except:
    print('')
" 2>/dev/null || echo "")

if [ -z "$TOKEN_VALUE" ]; then
    echo -e "${RED}❌ Não foi possível obter o token do cofre ${VAULT_VPS}${NC}"
    echo -e "${YELLOW}💡 Execute manualmente:${NC}"
    echo "   op item get $GH_TOKEN_VPS_ID --vault $VAULT_VPS --fields label=token"
    exit 1
fi

echo -e "${GREEN}✅ Token obtido com sucesso${NC}"
echo -e "${BLUE}📝 Criando item ${ITEM_TITLE} no cofre ${VAULT_MACOS}...${NC}"

# Criar item usando op item create
op item create \
    --category "API Credential" \
    --title "$ITEM_TITLE" \
    --vault "$VAULT_MACOS" \
    field[label="token"][value]="$TOKEN_VALUE" \
    field[label="notesPlain"][value]="GitHub Personal Access Token - Sincronizado do cofre ${VAULT_VPS} em $(date +%Y-%m-%d)" \
    url="https://github.com/settings/tokens" 2>&1 && {
    echo -e "${GREEN}✅ Item ${ITEM_TITLE} criado com sucesso no cofre ${VAULT_MACOS}!${NC}"
    echo ""
    echo -e "${BLUE}💡 Para usar o token:${NC}"
    echo "   export GH_TOKEN=\$(op item get ${ITEM_TITLE} --vault ${VAULT_MACOS} --fields label=token)"
    echo ""
} || {
    echo -e "${RED}❌ Erro ao criar item${NC}"
    echo -e "${YELLOW}💡 Tente criar manualmente no 1Password${NC}"
    exit 1
}

