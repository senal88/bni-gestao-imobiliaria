#!/usr/bin/env bash
# =========================================================
#  SCRIPT DE EXECUÇÃO PRINCIPAL
#  1. Executa o script Python para gerar o script de setup.
#  2. Executa o script de setup gerado.
# =========================================================

set -e

# Verifica se o Python 3 está disponível
if ! command -v python3 &> /dev/null
then
    echo "❌ ERRO: Python 3 não encontrado. Por favor, instale o Python 3."
    exit 1
fi

# Etapa 1: Gerar o script de shell a partir do contexto
echo "🐍 Executando o parser Python para gerar o script de setup..."
python3 parse_context.py

# Etapa 2: Executar o script gerado
if [ -f "generate-repo.sh" ]; then
    echo "🚀 Executando o script de setup gerado (generate-repo.sh)..."
    ./generate-repo.sh
else
    echo "❌ ERRO: O arquivo generate-repo.sh não foi criado pelo script Python."
    exit 1
fi

echo "🎉 Processo completo!"
