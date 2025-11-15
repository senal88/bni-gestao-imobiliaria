#!/bin/bash
# Execute este script para mudar branch padrão e deletar 'teab'

echo "🔧 Mudando Branch Padrão e Deletando 'teab'"
echo "============================================"
echo ""

# Verificar autenticação GitHub CLI
if ! gh auth status &> /dev/null; then
    echo "⚠️  Autenticação necessária no GitHub CLI"
    echo ""
    echo "Execute:"
    echo "  gh auth login"
    echo ""
    echo "Depois execute este script novamente"
    exit 1
fi

echo "📋 Mudando branch padrão para 'main'..."
gh api repos/senal88/bni-gestao-imobiliaria --method PATCH -f default_branch=main

echo "⏳ Aguardando propagação..."
sleep 3

echo "🗑️  Deletando branch 'teab'..."
git push origin --delete teab

echo ""
echo "✅ Concluído!"
echo ""
echo "📊 Verificação:"
git remote show origin | grep "HEAD branch"

