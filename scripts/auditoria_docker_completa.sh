#!/bin/bash
# Script de Auditoria Docker Completa
# Analisa todos os aspectos do ambiente Docker na VPS
# Evita conflitos e identifica problemas antes de deploy

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
AUDIT_DIR="./audit_reports"
REPORT_FILE="${AUDIT_DIR}/docker_audit_${TIMESTAMP}.txt"
JSON_REPORT="${AUDIT_DIR}/docker_audit_${TIMESTAMP}.json"

# Criar diretório de relatórios
mkdir -p "$AUDIT_DIR"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🔍 AUDITORIA DOCKER COMPLETA${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "📅 Data/Hora: $(date)"
echo "🖥️  Hostname: $(hostname)"
echo "📊 Relatório: $REPORT_FILE"
echo ""

# Função para escrever no relatório
write_report() {
    echo "$1" | tee -a "$REPORT_FILE"
}

# Função para escrever JSON
write_json() {
    echo "$1" >> "$JSON_REPORT"
}

# Iniciar JSON
echo "{" > "$JSON_REPORT"
write_json "  \"timestamp\": \"$(date -Iseconds)\","
write_json "  \"hostname\": \"$(hostname)\","
write_json "  \"docker_version\": \"$(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',' || echo 'N/A')\","

write_report "=========================================="
write_report "🔍 AUDITORIA DOCKER COMPLETA"
write_report "=========================================="
write_report "Data/Hora: $(date)"
write_report "Hostname: $(hostname)"
write_report ""

# ============================================
# 1. INFORMAÇÕES DO SISTEMA
# ============================================
echo -e "${CYAN}[1/10] Informações do Sistema${NC}"
write_report "=========================================="
write_report "1. INFORMAÇÕES DO SISTEMA"
write_report "=========================================="

DOCKER_VERSION=$(docker --version 2>/dev/null || echo "Docker não instalado")
DOCKER_COMPOSE_VERSION=$(docker-compose --version 2>/dev/null || docker compose version 2>/dev/null || echo "Docker Compose não instalado")

write_report "Docker: $DOCKER_VERSION"
write_report "Docker Compose: $DOCKER_COMPOSE_VERSION"
write_report "Sistema Operacional: $(uname -a)"
write_report "Uptime: $(uptime -p 2>/dev/null || uptime)"
write_report ""

# ============================================
# 2. CONTAINERS EM EXECUÇÃO
# ============================================
echo -e "${CYAN}[2/10] Containers em Execução${NC}"
write_report "=========================================="
write_report "2. CONTAINERS EM EXECUÇÃO"
write_report "=========================================="

RUNNING_CONTAINERS=$(docker ps --format "{{.Names}}" 2>/dev/null || echo "")
ALL_CONTAINERS=$(docker ps -a --format "{{.Names}}" 2>/dev/null || echo "")

if [ -n "$RUNNING_CONTAINERS" ]; then
    write_report "Containers em execução:"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" >> "$REPORT_FILE"
    write_report ""
    
    # Detectar containers BNI
    BNI_CONTAINERS=$(echo "$RUNNING_CONTAINERS" | grep -i "bni\|postgres\|pgadmin" || echo "")
    if [ -n "$BNI_CONTAINERS" ]; then
        write_report "⚠️  Containers BNI detectados:"
        echo "$BNI_CONTAINERS" | while read container; do
            write_report "   - $container"
        done
        write_report ""
    fi
else
    write_report "Nenhum container em execução"
    write_report ""
fi

# JSON para containers
write_json "  \"containers\": {"
write_json "    \"running\": ["
FIRST=true
for container in $RUNNING_CONTAINERS; do
    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        write_json ","
    fi
    CONTAINER_INFO=$(docker inspect "$container" --format '{"name":"{{.Name}}","image":"{{.Config.Image}}","status":"{{.State.Status}}","ports":"{{range $p, $conf := .NetworkSettings.Ports}}{{$p}} {{end}}"}' 2>/dev/null || echo "{}")
    write_json "      $CONTAINER_INFO"
done
write_json "    ],"

# ============================================
# 3. CONTAINERS PARADOS
# ============================================
echo -e "${CYAN}[3/10] Containers Parados${NC}"
write_report "=========================================="
write_report "3. CONTAINERS PARADOS"
write_report "=========================================="

STOPPED_CONTAINERS=$(docker ps -a --filter "status=exited" --format "{{.Names}}" 2>/dev/null || echo "")

if [ -n "$STOPPED_CONTAINERS" ]; then
    write_report "Containers parados:"
    docker ps -a --filter "status=exited" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" >> "$REPORT_FILE"
    write_report ""
else
    write_report "Nenhum container parado"
    write_report ""
fi

# ============================================
# 4. IMAGENS DOCKER
# ============================================
echo -e "${CYAN}[4/10] Imagens Docker${NC}"
write_report "=========================================="
write_report "4. IMAGENS DOCKER"
write_report "=========================================="

IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" 2>/dev/null || echo "")

if [ -n "$IMAGES" ]; then
    write_report "Imagens disponíveis:"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" >> "$REPORT_FILE"
    write_report ""
    
    # Verificar imagens BNI
    BNI_IMAGES=$(echo "$IMAGES" | grep -i "bni\|postgres\|pgadmin" || echo "")
    if [ -n "$BNI_IMAGES" ]; then
        write_report "⚠️  Imagens relacionadas ao BNI:"
        echo "$BNI_IMAGES" | while read image; do
            write_report "   - $image"
        done
        write_report ""
    fi
else
    write_report "Nenhuma imagem encontrada"
    write_report ""
fi

# ============================================
# 5. VOLUMES DOCKER
# ============================================
echo -e "${CYAN}[5/10] Volumes Docker${NC}"
write_report "=========================================="
write_report "5. VOLUMES DOCKER"
write_report "=========================================="

VOLUMES=$(docker volume ls --format "{{.Name}}" 2>/dev/null || echo "")

if [ -n "$VOLUMES" ]; then
    write_report "Volumes disponíveis:"
    docker volume ls >> "$REPORT_FILE"
    write_report ""
    
    # Verificar volumes BNI
    BNI_VOLUMES=$(echo "$VOLUMES" | grep -i "bni\|postgres\|pgadmin" || echo "")
    if [ -n "$BNI_VOLUMES" ]; then
        write_report "⚠️  Volumes relacionados ao BNI:"
        echo "$BNI_VOLUMES" | while read volume; do
            VOLUME_SIZE=$(docker system df -v 2>/dev/null | grep "$volume" | awk '{print $3}' || echo "N/A")
            write_report "   - $volume (Tamanho: $VOLUME_SIZE)"
        done
        write_report ""
    fi
else
    write_report "Nenhum volume encontrado"
    write_report ""
fi

# ============================================
# 6. REDES DOCKER
# ============================================
echo -e "${CYAN}[6/10] Redes Docker${NC}"
write_report "=========================================="
write_report "6. REDES DOCKER"
write_report "=========================================="

NETWORKS=$(docker network ls --format "{{.Name}}" 2>/dev/null || echo "")

if [ -n "$NETWORKS" ]; then
    write_report "Redes disponíveis:"
    docker network ls >> "$REPORT_FILE"
    write_report ""
    
    # Verificar rede BNI
    BNI_NETWORK=$(echo "$NETWORKS" | grep -i "bni" || echo "")
    if [ -n "$BNI_NETWORK" ]; then
        write_report "⚠️  Rede BNI detectada: $BNI_NETWORK"
        docker network inspect "$BNI_NETWORK" --format '{{range .Containers}}{{.Name}} {{end}}' >> "$REPORT_FILE" 2>/dev/null || true
        write_report ""
    fi
else
    write_report "Nenhuma rede encontrada"
    write_report ""
fi

# ============================================
# 7. USO DE RECURSOS
# ============================================
echo -e "${CYAN}[7/10] Uso de Recursos${NC}"
write_report "=========================================="
write_report "7. USO DE RECURSOS"
write_report "=========================================="

write_report "Estatísticas do Docker:"
docker system df >> "$REPORT_FILE" 2>/dev/null || write_report "Erro ao obter estatísticas"
write_report ""

write_report "Uso de CPU e Memória por container:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" >> "$REPORT_FILE" 2>/dev/null || write_report "Nenhum container em execução"
write_report ""

# ============================================
# 8. PORTAS EM USO
# ============================================
echo -e "${CYAN}[8/10] Portas em Uso${NC}"
write_report "=========================================="
write_report "8. PORTAS EM USO"
write_report "=========================================="

if [ -n "$RUNNING_CONTAINERS" ]; then
    write_report "Portas mapeadas:"
    docker ps --format "{{.Names}}: {{.Ports}}" >> "$REPORT_FILE"
    write_report ""
    
    # Verificar portas críticas
    PORTS_5432=$(docker ps --format "{{.Ports}}" | grep -o "5432" || echo "")
    PORTS_5050=$(docker ps --format "{{.Ports}}" | grep -o "5050" || echo "")
    
    if [ -n "$PORTS_5432" ]; then
        write_report "⚠️  Porta 5432 (PostgreSQL) em uso!"
        write_report "   Verifique conflitos antes de iniciar novo container PostgreSQL"
        write_report ""
    fi
    
    if [ -n "$PORTS_5050" ]; then
        write_report "⚠️  Porta 5050 (pgAdmin) em uso!"
        write_report ""
    fi
else
    write_report "Nenhuma porta em uso (sem containers rodando)"
    write_report ""
fi

# ============================================
# 9. CONFIGURAÇÕES DE SEGURANÇA
# ============================================
echo -e "${CYAN}[9/10] Configurações de Segurança${NC}"
write_report "=========================================="
write_report "9. CONFIGURAÇÕES DE SEGURANÇA"
write_report "=========================================="

# Verificar se containers rodam como root
ROOT_CONTAINERS=$(docker ps --format "{{.Names}}" | while read name; do
    USER=$(docker inspect "$name" --format '{{.Config.User}}' 2>/dev/null || echo "")
    if [ -z "$USER" ] || [ "$USER" = "root" ] || [ "$USER" = "0" ]; then
        echo "$name"
    fi
done)

if [ -n "$ROOT_CONTAINERS" ]; then
    write_report "⚠️  Containers rodando como root:"
    echo "$ROOT_CONTAINERS" | while read container; do
        write_report "   - $container"
    done
    write_report ""
fi

# Verificar se há containers com privilégios elevados
PRIVILEGED_CONTAINERS=$(docker ps --format "{{.Names}}" | while read name; do
    PRIVILEGED=$(docker inspect "$name" --format '{{.HostConfig.Privileged}}' 2>/dev/null || echo "false")
    if [ "$PRIVILEGED" = "true" ]; then
        echo "$name"
    fi
done)

if [ -n "$PRIVILEGED_CONTAINERS" ]; then
    write_report "⚠️  Containers com privilégios elevados:"
    echo "$PRIVILEGED_CONTAINERS" | while read container; do
        write_report "   - $container"
    done
    write_report ""
fi

# ============================================
# 10. ANÁLISE DE CONFLITOS POTENCIAIS
# ============================================
echo -e "${CYAN}[10/10] Análise de Conflitos Potenciais${NC}"
write_report "=========================================="
write_report "10. ANÁLISE DE CONFLITOS POTENCIAIS"
write_report "=========================================="

CONFLICTS_FOUND=false

# Verificar conflitos de portas
if [ -n "$PORTS_5432" ]; then
    write_report "❌ CONFLITO: Porta 5432 (PostgreSQL) já está em uso"
    write_report "   Solução: Use container existente ou mude a porta no docker-compose.prod.yml"
    CONFLICTS_FOUND=true
fi

if [ -n "$PORTS_5050" ]; then
    write_report "❌ CONFLITO: Porta 5050 (pgAdmin) já está em uso"
    write_report "   Solução: Use container existente ou mude a porta no docker-compose.prod.yml"
    CONFLICTS_FOUND=true
fi

# Verificar se há containers PostgreSQL existentes
if [ -n "$BNI_CONTAINERS" ]; then
    write_report "⚠️  ATENÇÃO: Containers BNI já existem"
    write_report "   Verifique se deseja usar containers existentes antes de criar novos"
    CONFLICTS_FOUND=true
fi

# Verificar espaço em disco
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    write_report "⚠️  ATENÇÃO: Uso de disco acima de 80% ($DISK_USAGE%)"
    write_report "   Considere limpar imagens e volumes não utilizados"
    CONFLICTS_FOUND=true
fi

if [ "$CONFLICTS_FOUND" = false ]; then
    write_report "✅ Nenhum conflito potencial detectado"
fi

write_report ""

# ============================================
# RESUMO E RECOMENDAÇÕES
# ============================================
write_report "=========================================="
write_report "RESUMO E RECOMENDAÇÕES"
write_report "=========================================="
write_report ""

TOTAL_CONTAINERS=$(echo "$ALL_CONTAINERS" | wc -l)
RUNNING_COUNT=$(echo "$RUNNING_CONTAINERS" | wc -l)
STOPPED_COUNT=$(echo "$STOPPED_CONTAINERS" | wc -l)

write_report "Total de containers: $TOTAL_CONTAINERS"
write_report "   Em execução: $RUNNING_COUNT"
write_report "   Parados: $STOPPED_COUNT"
write_report ""

write_report "RECOMENDAÇÕES:"
write_report "1. Se houver containers PostgreSQL existentes, considere reutilizá-los"
write_report "2. Verifique portas em uso antes de iniciar novos containers"
write_report "3. Mantenha backups regulares dos volumes Docker"
write_report "4. Monitore uso de recursos (CPU/Memória/Disk)"
write_report "5. Revise configurações de segurança periodicamente"
write_report ""

# Finalizar JSON
write_json "  }"
write_json "}"

echo -e "${GREEN}✅ Auditoria concluída!${NC}"
echo -e "${BLUE}📊 Relatório salvo em: $REPORT_FILE${NC}"
echo -e "${BLUE}📊 JSON salvo em: $JSON_REPORT${NC}"
echo ""

# Mostrar resumo na tela
echo -e "${CYAN}📋 RESUMO RÁPIDO:${NC}"
echo "   Containers em execução: $RUNNING_COUNT"
echo "   Containers parados: $STOPPED_COUNT"
if [ "$CONFLICTS_FOUND" = true ]; then
    echo -e "   ${YELLOW}⚠️  Conflitos detectados - revise o relatório${NC}"
else
    echo -e "   ${GREEN}✅ Nenhum conflito detectado${NC}"
fi
echo ""

