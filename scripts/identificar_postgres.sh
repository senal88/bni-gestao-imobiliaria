#!/bin/bash
# Script para identificar containers PostgreSQL no VPS

echo "🔍 Identificando containers PostgreSQL..."
echo "=========================================="
echo ""

# Verificar containers PostgreSQL rodando
echo "📦 Containers PostgreSQL ATIVOS:"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | grep -i postgres || echo "Nenhum container PostgreSQL ativo encontrado"
echo ""

# Verificar todos os containers PostgreSQL (incluindo parados)
echo "📦 Todos os containers PostgreSQL:"
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | grep -i postgres || echo "Nenhum container PostgreSQL encontrado"
echo ""

# Listar informações detalhadas
echo "📋 Informações detalhadas dos containers PostgreSQL:"
echo ""

POSTGRES_CONTAINERS=$(docker ps -a --format "{{.Names}}" | grep -i postgres)

if [ -z "$POSTGRES_CONTAINERS" ]; then
    echo "⚠️  Nenhum container PostgreSQL encontrado"
    echo ""
    echo "💡 Para criar um novo container PostgreSQL:"
    echo "   docker run -d --name bni_postgres \\"
    echo "     -e POSTGRES_DB=bni_gestao \\"
    echo "     -e POSTGRES_USER=postgres \\"
    echo "     -e POSTGRES_PASSWORD=sua_senha \\"
    echo "     -p 5432:5432 \\"
    echo "     postgres:14-alpine"
else
    for container in $POSTGRES_CONTAINERS; do
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Container: $container"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # Status
        STATUS=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null || echo "N/A")
        echo "Status: $STATUS"

        # Portas
        PORTS=$(docker port "$container" 2>/dev/null || echo "N/A")
        echo "Portas: $PORTS"

        # Variáveis de ambiente
        echo ""
        echo "Variáveis de ambiente:"
        docker inspect --format='{{range .Config.Env}}{{println .}}{{end}}' "$container" 2>/dev/null | grep -i postgres || echo "N/A"

        # Testar conexão se estiver rodando
        if [ "$STATUS" = "running" ]; then
            echo ""
            echo "🧪 Testando conexão..."
            docker exec "$container" psql -U postgres -c "SELECT version();" 2>/dev/null && echo "✅ Conexão OK" || echo "❌ Erro na conexão"
        fi

        echo ""
    done

    echo ""
    echo "💡 Para usar um container existente, configure os secrets do GitHub:"
    echo "   POSTGRES_HOST: localhost (ou nome do container)"
    echo "   POSTGRES_PORT: 5432 (ou porta mapeada)"
    echo "   POSTGRES_DB: bni_gestao (ou criar com: docker exec -it <container> psql -U postgres -c 'CREATE DATABASE bni_gestao;')"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📚 Próximos passos:"
echo "1. Escolha um container PostgreSQL ou crie um novo"
echo "2. Configure os secrets no GitHub com as informações acima"
echo "3. Teste o deploy manualmente"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

