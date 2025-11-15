# 🔍 Análise de Mudanças na VPS

Documento que analisa as mudanças realizadas na VPS para evitar conflitos durante deploy.

## 📋 Mudanças Identificadas

### 1. Containers Docker

#### Containers PostgreSQL Existentes
A VPS pode ter múltiplos containers PostgreSQL rodando:

```bash
# Verificar containers PostgreSQL
docker ps | grep postgres
```

**Possíveis containers:**
- `postgres-fk0kg4gk80k4sowc400wc4sw` (ghcr.io/fazer-ai/postgres-16-pgvector)
- `postgresql-iccg8w0w8kg0s0ok8408o0gc` (postgres:16-alpine)
- `coolify-db` (postgres:15-alpine)
- `bni_postgres_prod` (postgres:14-alpine) - **Nosso container**

#### Estratégia de Deploy

**Opção A: Usar Container Existente (Recomendado)**
- Reutilizar container PostgreSQL existente
- Criar banco `bni_gestao` dentro do container existente
- Evita conflitos de porta e recursos

**Opção B: Criar Container Dedicado**
- Usar `docker-compose.prod.yml`
- Container isolado: `bni_postgres_prod`
- Porta: `127.0.0.1:5432` (apenas localhost)

### 2. Portas em Uso

#### Portas Críticas

| Porta | Serviço | Status | Ação |
|-------|---------|--------|------|
| 5432 | PostgreSQL | ⚠️ Pode estar em uso | Verificar antes de criar novo container |
| 5050 | pgAdmin | ⚠️ Pode estar em uso | Verificar antes de criar novo container |

#### Verificação de Portas

```bash
# Verificar portas em uso
netstat -tulpn | grep -E "5432|5050"
# ou
ss -tulpn | grep -E "5432|5050"
```

### 3. Volumes Docker

#### Volumes Existentes

```bash
# Listar volumes
docker volume ls
```

**Volumes BNI:**
- `postgres_data` - Dados do PostgreSQL
- `pgadmin_data` - Dados do pgAdmin

**⚠️ ATENÇÃO:** Não deletar volumes existentes sem backup!

### 4. Redes Docker

#### Rede BNI

```bash
# Verificar rede
docker network ls | grep bni
```

**Rede esperada:**
- `bni_internal` - Rede isolada para comunicação entre serviços

### 5. Deploy Workflow

#### GitHub Actions Deploy

O workflow `.github/workflows/deploy-postgres.yml` executa:

```bash
cd /opt/bni-gestao-imobiliaria
git pull origin main
python3 -m pip install -r requirements.txt --quiet
python3 scripts/init_database.py
```

**⚠️ PONTOS DE ATENÇÃO:**
1. Não cria containers Docker (assume que já existem)
2. Atualiza código do repositório
3. Executa `init_database.py` que agora usa `init.sql` completo

### 6. Scripts de Setup

#### Scripts Disponíveis

1. **`scripts/setup_vps_docker.sh`**
   - Setup completo com Docker Compose
   - Pergunta se quer usar container existente ou criar novo
   - Gera senhas automaticamente

2. **`scripts/setup_vps_completo.sh`**
   - Setup manual sem Docker
   - Instala PostgreSQL diretamente no sistema

3. **`scripts/setup_vps_completo_1p.sh`**
   - Setup com integração 1Password
   - Carrega secrets automaticamente

## 🚨 Conflitos Potenciais

### Conflito 1: Porta 5432 em Uso

**Sintoma:**
```
Error: bind: address already in use
```

**Solução:**
```bash
# Opção 1: Usar container existente
docker exec -it <container_existente> psql -U postgres -c "CREATE DATABASE bni_gestao;"

# Opção 2: Mudar porta no docker-compose.prod.yml
ports:
  - "127.0.0.1:5433:5432"  # Usar porta alternativa
```

### Conflito 2: Volume Já Existe

**Sintoma:**
```
Error: volume already exists
```

**Solução:**
```bash
# Reutilizar volume existente
docker-compose -f docker-compose.prod.yml up -d
# O Docker Compose reutilizará o volume automaticamente
```

### Conflito 3: Rede Já Existe

**Sintoma:**
```
Error: network already exists
```

**Solução:**
```bash
# Reutilizar rede existente (comportamento padrão)
# Nenhuma ação necessária
```

### Conflito 4: Schema Incompleto

**Sintoma:**
```
Error: column "codigo_cc" does not exist
```

**Solução:**
```bash
# Executar init_database.py que agora usa init.sql completo
python3 scripts/init_database.py
```

## ✅ Checklist Antes de Deploy

- [ ] Executar auditoria Docker: `./scripts/auditoria_docker_completa.sh`
- [ ] Verificar containers PostgreSQL existentes
- [ ] Verificar portas em uso (5432, 5050)
- [ ] Verificar volumes Docker
- [ ] Verificar espaço em disco
- [ ] Fazer backup dos dados existentes
- [ ] Verificar variáveis de ambiente (.env)
- [ ] Verificar conexão com banco de dados

## 🔄 Processo de Deploy Seguro

### Passo 1: Auditoria

```bash
# Na VPS
cd /opt/bni-gestao-imobiliaria
./scripts/auditoria_docker_completa.sh
```

### Passo 2: Backup

```bash
# Backup do banco de dados
docker exec bni_postgres_prod pg_dump -U postgres bni_gestao > backup_$(date +%Y%m%d).sql

# Backup dos volumes
docker run --rm -v postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/postgres_data_backup_$(date +%Y%m%d).tar.gz /data
```

### Passo 3: Deploy

```bash
# Atualizar código
git pull origin main

# Verificar mudanças
git log --oneline -5

# Executar deploy
python3 scripts/init_database.py
```

### Passo 4: Validação

```bash
# Verificar containers
docker ps | grep bni_

# Verificar logs
docker logs bni_postgres_prod

# Testar conexão
python3 scripts/init_database.py --validate-only
```

## 📊 Monitoramento

### Comandos Úteis

```bash
# Status dos containers
docker-compose -f docker-compose.prod.yml ps

# Logs em tempo real
docker-compose -f docker-compose.prod.yml logs -f

# Uso de recursos
docker stats

# Espaço em disco
docker system df
```

## 🔗 Referências

- [Docker Compose Production](./docker-compose.prod.yml)
- [Setup VPS Docker](./SETUP_VPS_DOCKER.md)
- [Auditoria Docker](./scripts/auditoria_docker_completa.sh)

