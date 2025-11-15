#!/bin/bash
# Script Enterprise para trocar default branch e deletar 'teab' via API
# 100% automatizado - não trava em caso de erro

set -e

REPO="senal88/bni-gestao-imobiliaria"
BRANCH="teab"
NEW_DEFAULT="main"

# Verificar se GH_TOKEN está configurado
if [ -z "$GH_TOKEN" ]; then
    echo "❌ GH_TOKEN não configurado"
    echo ""
    echo "Configure com:"
    echo "  export GH_TOKEN=seu_token_aqui"
    echo ""
    echo "Obter token em: https://github.com/settings/tokens"
    echo "Permissões necessárias: repo"
    exit 1
fi

echo "🔍 Ajustando default branch para '${NEW_DEFAULT}' no repositório ${REPO}..."

# Mudar branch padrão via API
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH \
  -H "Authorization: token ${GH_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${REPO}" \
  -d "{\"default_branch\": \"${NEW_DEFAULT}\"}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Default branch alterada para '${NEW_DEFAULT}'"
else
    echo "⚠️  Resposta HTTP: $HTTP_CODE"
    echo "$RESPONSE" | head -n-1 | jq . 2>/dev/null || echo "$RESPONSE" | head -n-1
    exit 1
fi

# Aguardar propagação
echo "⏳ Aguardando propagação..."
sleep 3

# Deletar branch remota
echo "🧹 Removendo branch remota '${BRANCH}'..."
git push https://github.com/${REPO}.git --delete ${BRANCH} 2>&1 || echo "⚠️  Branch remota já removida ou não existe"

# Deletar branch local (se existir)
echo "🧹 Removendo branch local '${BRANCH}'..."
git branch -D ${BRANCH} 2>&1 || echo "⚠️  Branch local já removida ou não existe"

echo ""
echo "🎉 Processo finalizado!"
echo ""
echo "📊 Verificação:"
git remote show origin | grep "HEAD branch" || echo "Execute: git remote show origin"

