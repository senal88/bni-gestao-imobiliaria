#!/bin/bash
# Script alternativo usando curl (sem GitHub CLI)
# Requer GITHUB_TOKEN como variável de ambiente

set -e

echo "🔧 Mudando Branch Padrão via API (curl)"
echo "========================================"
echo ""

REPO="senal88/bni-gestao-imobiliaria"

# Verificar token
if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ GITHUB_TOKEN não configurado"
    echo ""
    echo "Configure com:"
    echo "  export GITHUB_TOKEN=seu_token_aqui"
    echo ""
    echo "Obter token em: https://github.com/settings/tokens"
    echo "Permissões necessárias: repo"
    exit 1
fi

echo "📋 Verificando branch padrão atual..."
CURRENT_DEFAULT=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$REPO" | \
    grep -o '"default_branch":"[^"]*"' | \
    cut -d'"' -f4)

echo "   Branch padrão atual: $CURRENT_DEFAULT"

if [ "$CURRENT_DEFAULT" = "main" ]; then
    echo "✅ Branch padrão já é 'main'"
else
    echo "🔄 Mudando branch padrão para 'main'..."
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -d '{"default_branch":"main"}' \
        "https://api.github.com/repos/$REPO")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ Branch padrão alterada para 'main'"
        sleep 2
    else
        echo "❌ Erro ao mudar branch padrão (HTTP $HTTP_CODE)"
        echo "$RESPONSE" | head -n-1
        exit 1
    fi
fi

echo ""
echo "🗑️  Deletando branch 'teab' remota..."

if git ls-remote --heads origin teab | grep -q teab; then
    git push origin --delete teab
    echo "✅ Branch 'teab' deletada com sucesso!"
else
    echo "ℹ️  Branch 'teab' não existe mais"
fi

echo ""
echo "✅ Concluído!"

