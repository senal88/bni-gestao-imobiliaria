#!/bin/bash
# Script para mudar branch padrão para 'main' e deletar 'teab' via CLI
# Execute este script NO MAC

set -e

echo "🔧 Mudando Branch Padrão e Deletando 'teab'"
echo "============================================"
echo ""

REPO="senal88/bni-gestao-imobiliaria"

# Verificar se GitHub CLI está instalado
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI não encontrado"
    echo ""
    echo "Instale com:"
    echo "  brew install gh"
    echo ""
    echo "Ou use a API diretamente com curl (veja script alternativo)"
    exit 1
fi

# Verificar autenticação
if ! gh auth status &> /dev/null; then
    echo "⚠️  Não autenticado no GitHub CLI"
    echo "   Autenticando..."
    gh auth login
fi

echo "📋 Verificando branch padrão atual..."
CURRENT_DEFAULT=$(gh api repos/$REPO --jq .default_branch)
echo "   Branch padrão atual: $CURRENT_DEFAULT"

if [ "$CURRENT_DEFAULT" = "main" ]; then
    echo "✅ Branch padrão já é 'main'"
else
    echo "🔄 Mudando branch padrão de '$CURRENT_DEFAULT' para 'main'..."
    gh api repos/$REPO --method PATCH -f default_branch=main

    # Aguardar propagação
    sleep 2

    # Verificar
    NEW_DEFAULT=$(gh api repos/$REPO --jq .default_branch)
    if [ "$NEW_DEFAULT" = "main" ]; then
        echo "✅ Branch padrão alterada para 'main'"
    else
        echo "❌ Erro ao mudar branch padrão"
        exit 1
    fi
fi

echo ""
echo "🗑️  Deletando branch 'teab' remota..."

# Verificar se branch existe
if git ls-remote --heads origin teab | grep -q teab; then
    git push origin --delete teab
    echo "✅ Branch 'teab' deletada com sucesso!"
else
    echo "ℹ️  Branch 'teab' não existe mais"
fi

echo ""
echo "✅ Concluído!"
echo ""
echo "📊 Verificação:"
git remote show origin | grep "HEAD branch"

