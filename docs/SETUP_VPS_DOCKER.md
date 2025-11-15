# 🐳 Setup Completo com Docker na VPS

Guia específico para setup usando **Docker Compose** na VPS OVH.

## 🎯 Visão Geral

Este setup usa Docker Compose para gerenciar todos os serviços:
- ✅ PostgreSQL em container isolado
- ✅ pgAdmin para gerenciamento visual
- ✅ Rede isolada entre serviços
- ✅ Volumes persistentes para dados
- ✅ Healthchecks e restart automático
- ✅ Limites de recursos configurados

## ⚡ Setup Rápido (Recomendado)

### 1. Conectar na VPS

**No seu Mac:**

```bash
ssh vps
```

### 2. Executar Script Automatizado

**Na VPS:**

```bash
# Criar diretório e clonar repositório
mkdir -p /opt/bni-gestao-imobiliaria
cd /opt/bni-gestao-imobiliaria
git clone https://github.com/senal88/bni-gestao-imobiliaria.git .

# Executar script de setup
chmod +x scripts/setup_vps_docker.sh
./scripts/setup_vps_docker.sh
```

O script irá:
1. ✅ Verificar/instalar Docker
2. ✅ Criar estrutura de diretórios
3. ✅ Perguntar se quer usar container PostgreSQL existente ou criar novo
4. ✅ Configurar docker-compose.prod.yml
5. ✅ Gerar senhas seguras
6. ✅ Iniciar containers
7. ✅ Configurar ambiente Python
8. ✅ Inicializar banco de dados

## 📋 Setup Manual Passo a Passo

### Passo 1: Preparar Ambiente

```bash
# Na VPS
cd /opt/bni-gestao-imobiliaria
git clone https://github.com/senal88/bni-gestao-imobiliaria.git .
```

### Passo 2: Configurar Variáveis de Ambiente

```bash
# Criar .env.prod com senhas
cat > .env.prod << EOF
POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
POSTGRES_DB=bni_gestao
POSTGRES_USER=postgres
PGADMIN_EMAIL=admin@bni.local
PGADMIN_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-12)
EOF

chmod 600 .env.prod

# Criar .env para aplicação Python
cat > .env << EOF
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=bni_gestao
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$(grep POSTGRES_PASSWORD .env.prod | cut -d'=' -f2)

HF_TOKEN=
HF_DATASET_NAME=senal88/bni-gestao-imobiliaria

DATA_RAW_PATH=/opt/bni-gestao-imobiliaria/data/raw
DATA_PROCESSED_PATH=/opt/bni-gestao-imobiliaria/data/processed
DATA_SCHEMAS_PATH=/opt/bni-gestao-imobiliaria/data/schemas

LOG_LEVEL=INFO
LOG_FILE=/opt/bni-gestao-imobiliaria/logs/bni_gestao.log
EOF

chmod 600 .env
```

### Passo 3: Iniciar Containers

```bash
# Iniciar PostgreSQL e pgAdmin
docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d

# Verificar status
docker-compose -f docker-compose.prod.yml ps

# Ver logs
docker-compose -f docker-compose.prod.yml logs -f
```

### Passo 4: Configurar Python

```bash
# Criar ambiente virtual
python3 -m venv venv
source venv/bin/activate

# Instalar dependências
pip install --upgrade pip
pip install -r requirements.txt
```

### Passo 5: Inicializar Banco

```bash
# Aguardar PostgreSQL estar pronto
sleep 10

# Inicializar banco
export $(cat .env | grep -v '^#' | xargs)
python scripts/init_database.py
```

### Passo 6: Importar Dados

```bash
# Validar schemas
python scripts/validate_schemas.py

# Importar propriedades
python scripts/import_propriedades.py
```

## 🔧 Comandos Úteis

### Gerenciar Containers

```bash
# Ver status
docker-compose -f docker-compose.prod.yml ps

# Ver logs
docker-compose -f docker-compose.prod.yml logs -f postgres

# Reiniciar serviço
docker-compose -f docker-compose.prod.yml restart postgres

# Parar tudo
docker-compose -f docker-compose.prod.yml down

# Parar e remover volumes (CUIDADO!)
docker-compose -f docker-compose.prod.yml down -v
```

### Acessar Banco de Dados

```bash
# Via docker exec
docker exec -it bni_postgres_prod psql -U postgres -d bni_gestao

# Via psql local (se instalado)
psql -h localhost -U postgres -d bni_gestao
```

### Backup e Restore

```bash
# Backup
docker exec bni_postgres_prod pg_dump -U postgres bni_gestao > backup_$(date +%Y%m%d).sql

# Restore
docker exec -i bni_postgres_prod psql -U postgres bni_gestao < backup_20250115.sql
```

### Acessar pgAdmin

```bash
# Via SSH tunnel (do seu Mac)
ssh -L 5050:localhost:5050 vps

# Depois acesse no navegador do Mac:
# http://localhost:5050
# Login: admin@bni.local / senha do .env.prod
```

## 🔒 Segurança

### Verificações Importantes

```bash
# Verificar permissões do .env
ls -la .env .env.prod
# Deve mostrar: -rw------- (600)

# Verificar rede isolada
docker network inspect bni-gestao-imobiliaria_bni_internal

# Verificar limites de recursos
docker stats bni_postgres_prod
```

### Boas Práticas Aplicadas

- ✅ Senhas geradas aleatoriamente
- ✅ Arquivos .env com permissão 600
- ✅ PostgreSQL apenas em localhost (127.0.0.1)
- ✅ Rede isolada entre serviços
- ✅ Limites de recursos configurados
- ✅ Healthchecks em todos os serviços
- ✅ Logging com rotação
- ✅ Labels para organização

## 🐛 Troubleshooting

### Container não inicia

```bash
# Ver logs detalhados
docker-compose -f docker-compose.prod.yml logs postgres

# Verificar se porta está em uso
netstat -tulpn | grep 5432

# Verificar volumes
docker volume ls | grep bni
```

### Erro de conexão

```bash
# Verificar se PostgreSQL está pronto
docker exec bni_postgres_prod pg_isready -U postgres

# Testar conexão
docker exec bni_postgres_prod psql -U postgres -c "SELECT 1;"
```

### Problemas de permissão

```bash
# Verificar usuário do container
docker exec bni_postgres_prod whoami

# Verificar permissões de volumes
docker inspect bni-gestao-imobiliaria_postgres_data
```

## 📊 Monitoramento

### Ver uso de recursos

```bash
# Stats em tempo real
docker stats

# Apenas containers BNI
docker stats bni_postgres_prod bni_pgadmin_prod
```

### Ver logs

```bash
# Todos os serviços
docker-compose -f docker-compose.prod.yml logs

# Apenas PostgreSQL
docker-compose -f docker-compose.prod.yml logs postgres

# Últimas 100 linhas
docker-compose -f docker-compose.prod.yml logs --tail=100
```

## 🔄 Atualização

### Atualizar código

```bash
cd /opt/bni-gestao-imobiliaria
git pull origin teab

# Se houver mudanças no schema
source venv/bin/activate
python scripts/init_database.py
```

### Atualizar containers

```bash
# Reconstruir e reiniciar
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d
```

## 📚 Referências

- [`SETUP_VPS.md`](SETUP_VPS.md) - Setup geral na VPS
- [`GUIA_RAPIDO.md`](GUIA_RAPIDO.md) - Mac vs VPS
- [Docker Compose Documentation](https://docs.docker.com/compose/)

