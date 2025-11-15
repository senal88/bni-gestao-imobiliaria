#!/bin/bash
# Script para listar todos os repositórios onde default branch ≠ main
# Automação em escala

set -e

# Verificar se GH_TOKEN está configurado
if [ -z "$GH_TOKEN" ]; then
    echo "❌ GH_TOKEN não configurado"
    echo ""
    echo "Configure com:"
    echo "  export GH_TOKEN=seu_token_aqui"
    exit 1
fi

USER="senal88"

echo "🔍 Listando repositórios onde default branch ≠ 'main'..."
echo "========================================================"
echo ""

# Listar todos os repositórios do usuário
REPOS=$(curl -s -H "Authorization: token ${GH_TOKEN}" \
    "https://api.github.com/users/${USER}/repos?per_page=100&type=all" | \
    jq -r '.[].full_name')

COUNT=0
TOTAL=0

for REPO in $REPOS; do
    TOTAL=$((TOTAL + 1))

    # Obter branch padrão
    DEFAULT_BRANCH=$(curl -s -H "Authorization: token ${GH_TOKEN}" \
        "https://api.github.com/repos/${REPO}" | \
        jq -r '.default_branch')

    if [ "$DEFAULT_BRANCH" != "main" ] && [ "$DEFAULT_BRANCH" != "null" ]; then
        COUNT=$((COUNT + 1))
        echo "📦 $REPO"
        echo "   Default branch: $DEFAULT_BRANCH"
        echo ""
    fi
done

echo "========================================================"
echo "📊 Resumo:"
echo "   Total de repositórios: $TOTAL"
echo "   Com default ≠ 'main': $COUNT"
echo ""

if [ $COUNT -eq 0 ]; then
    echo "✅ Todos os repositórios já usam 'main' como padrão!"
else
    echo "⚠️  $COUNT repositório(s) precisam de correção"
    echo ""
    echo "Para corrigir todos, execute:"
    echo "  ./scripts/corrigir_todos_repos.sh"
fi

