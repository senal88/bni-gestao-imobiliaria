#!/bin/bash
# Script para migrar branch teab para main
# Execute este script NO MAC (não na VPS)

set -e

echo "🔄 Migração: teab → main"
echo "========================"
echo ""

# Verificar se está no diretório correto
if [ ! -d ".git" ]; then
    echo "❌ Este script deve ser executado no diretório do repositório"
    exit 1
fi

# Verificar branch atual
CURRENT_BRANCH=$(git branch --show-current)
echo "📍 Branch atual: $CURRENT_BRANCH"

if [ "$CURRENT_BRANCH" != "teab" ]; then
    echo "⚠️  Você não está na branch 'teab'"
    read -p "   Continuar mesmo assim? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
fi

# Verificar se há mudanças não commitadas
if [ -n "$(git status --porcelain)" ]; then
    echo "📝 Há mudanças não commitadas"
    read -p "   Fazer commit antes de migrar? (S/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        git add .
        git commit -m "feat: estrutura completa do projeto BNI Gestão Imobiliária

- Adiciona scripts Python para gestão de propriedades
- Configura GitHub Actions para CI/CD
- Adiciona Docker Compose para Mac e VPS
- Integra 1Password para gerenciamento de secrets
- Adiciona documentação completa em português
- Inclui dataset com 38 propriedades do portfólio BNI
- Configura schemas de validação e relatórios IFRS"
        echo "✅ Mudanças commitadas"
    fi
fi

# Verificar se main já existe
if git show-ref --verify --quiet refs/heads/main; then
    echo "⚠️  Branch 'main' já existe localmente"
    read -p "   Fazer merge de 'teab' em 'main'? (S/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        git checkout main
        git merge teab --no-edit
        echo "✅ Merge concluído"
    else
        echo "❌ Migração cancelada"
        exit 1
    fi
else
    # Renomear teab para main
    echo "🔄 Renomeando branch 'teab' para 'main'..."
    git branch -m teab main
    echo "✅ Branch renomeada localmente"
fi

# Verificar se GitHub CLI está instalado
if command -v gh &> /dev/null; then
    echo ""
    echo "📤 Enviando 'main' para GitHub..."
    git push origin main

    echo ""
    echo "🔧 Definindo 'main' como branch padrão no GitHub..."
    gh api repos/senal88/bni-gestao-imobiliaria --method PATCH -f default_branch=main 2>/dev/null || {
        echo "⚠️  Não foi possível definir via CLI"
        echo "   Defina manualmente em:"
        echo "   https://github.com/senal88/bni-gestao-imobiliaria/settings/branches"
    }

    echo ""
    read -p "   Deletar branch 'teab' remota? (s/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        git push origin --delete teab 2>/dev/null || echo "⚠️  Branch 'teab' remota não existe ou já foi deletada"
    fi
else
    echo ""
    echo "📤 Enviando 'main' para GitHub..."
    git push origin main

    echo ""
    echo "⚠️  GitHub CLI não encontrado"
    echo "   Execute manualmente:"
    echo "   1. git push origin main"
    echo "   2. Acesse: https://github.com/senal88/bni-gestao-imobiliaria/settings/branches"
    echo "   3. Defina 'main' como Default branch"
    echo "   4. (Opcional) Delete branch 'teab' remota"
fi

echo ""
echo "✅ Migração concluída!"
echo ""
echo "📍 Próximos passos:"
echo "   1. Verificar branch padrão no GitHub"
echo "   2. Testar GitHub Actions (fazer um push para main)"
echo "   3. Atualizar configurações locais se necessário"

