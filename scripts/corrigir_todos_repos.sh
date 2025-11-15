#!/bin/bash
# Script para corrigir todos os repositórios: mudar default para 'main' e deletar branches antigas
# Automação em escala - USE COM CUIDADO!

set -e

# Verificar se GH_TOKEN está configurado
if [ -z "$GH_TOKEN" ]; then
    echo "❌ GH_TOKEN não configurado"
    echo "  export GH_TOKEN=seu_token_aqui"
    exit 1
fi

USER="senal88"
BRANCHES_ANTIGAS="teab master"

echo "⚠️  ATENÇÃO: Este script vai modificar TODOS os seus repositórios!"
echo "================================================================"
echo ""
read -p "   Continuar? (s/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "❌ Cancelado"
    exit 1
fi

echo ""
echo "🔍 Listando repositórios..."
REPOS=$(curl -s -H "Authorization: token ${GH_TOKEN}" \
    "https://api.github.com/users/${USER}/repos?per_page=100&type=all" | \
    jq -r '.[].full_name')

CORRIGIDOS=0
ERROS=0

for REPO in $REPOS; do
    echo ""
    echo "📦 Processando: $REPO"

    # Obter branch padrão atual
    DEFAULT_BRANCH=$(curl -s -H "Authorization: token ${GH_TOKEN}" \
        "https://api.github.com/repos/${REPO}" | \
        jq -r '.default_branch')

    echo "   Branch padrão atual: $DEFAULT_BRANCH"

    # Se já é main, pular
    if [ "$DEFAULT_BRANCH" = "main" ]; then
        echo "   ✅ Já usa 'main', pulando..."
        continue
    fi

    # Verificar se main existe
    MAIN_EXISTS=$(curl -s -H "Authorization: token ${GH_TOKEN}" \
        "https://api.github.com/repos/${REPO}/branches/main" | \
        jq -r '.name' 2>/dev/null || echo "")

    if [ -z "$MAIN_EXISTS" ]; then
        echo "   ⚠️  Branch 'main' não existe neste repositório"
        echo "   ⚠️  Pulando (crie 'main' manualmente primeiro)"
        continue
    fi

    # Mudar branch padrão para main
    echo "   🔄 Mudando default branch para 'main'..."
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH \
        -H "Authorization: token ${GH_TOKEN}" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/${REPO}" \
        -d "{\"default_branch\": \"main\"}")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

    if [ "$HTTP_CODE" = "200" ]; then
        echo "   ✅ Default branch alterada para 'main'"
        CORRIGIDOS=$((CORRIGIDOS + 1))
        sleep 1

        # Tentar deletar branches antigas (se existirem)
        for OLD_BRANCH in $BRANCHES_ANTIGAS; do
            if [ "$OLD_BRANCH" = "$DEFAULT_BRANCH" ]; then
                echo "   🗑️  Branch '$OLD_BRANCH' era a padrão, não deletando automaticamente"
                echo "   ⚠️  Delete manualmente após verificar que 'main' está funcionando"
            fi
        done
    else
        echo "   ❌ Erro ao mudar branch padrão (HTTP $HTTP_CODE)"
        ERROS=$((ERROS + 1))
    fi
done

echo ""
echo "========================================================"
echo "📊 Resumo:"
echo "   Repositórios corrigidos: $CORRIGIDOS"
echo "   Erros: $ERROS"
echo ""
echo "✅ Processo concluído!"

