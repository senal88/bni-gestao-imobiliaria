# 🖥️ Setup Completo na VPS

Este guia é específico para **configuração na VPS OVH** (servidor de produção).

## 📋 Informações da VPS

- **Hostname**: `senamfo`
- **IP**: `147.79.81.59`
- **Usuário**: `root`
- **Sistema**: Linux (Ubuntu/Debian)
- **Acesso**: `ssh vps` (configurado no seu Mac)

## 🚀 Passo 1: Conectar na VPS

**No seu Mac, execute:**

```bash
ssh vps
```

Agora você está **dentro da VPS**.

### ⚡ Setup Rápido com Script Automatizado

Se quiser setup completo automatizado:

```bash
# Na VPS
cd /opt/bni-gestao-imobiliaria
./scripts/setup_vps_docker.sh
```

Este script faz tudo automaticamente! Ou continue com os passos manuais abaixo.

## 📦 Passo 2: Instalar Dependências na VPS

**Execute na VPS:**

```bash
# Atualizar sistema
apt update && apt upgrade -y

# Instalar dependências básicas
apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    docker.io \
    docker-compose \
    postgresql-client \
    curl \
    wget \
    vim

# Verificar versões
python3 --version
docker --version
docker-compose --version
```

## 🐳 Passo 3: Configurar Docker na VPS

**Execute na VPS:**

```bash
# Adicionar usuário ao grupo docker (se necessário)
usermod -aG docker root

# Iniciar e habilitar Docker
systemctl start docker
systemctl enable docker

# Verificar se Docker está rodando
docker ps
```

## 📁 Passo 4: Criar Estrutura de Diretórios na VPS

**Execute na VPS:**

```bash
# Criar diretório de deploy
mkdir -p /opt/bni-gestao-imobiliaria
cd /opt/bni-gestao-imobiliaria

# Criar estrutura de diretórios
mkdir -p data/{raw,processed,schemas}
mkdir -p scripts
mkdir -p logs
mkdir -p reports/ifrs
mkdir -p obsidian/vault_backup
```

## 🔄 Passo 5: Clonar Repositório na VPS

**Execute na VPS:**

```bash
cd /opt/bni-gestao-imobiliaria

# Clonar repositório
git clone https://github.com/senal88/bni-gestao-imobiliaria.git .

# Ou se já existe, atualizar
git pull origin teab
```

## 🐘 Passo 6: Configurar PostgreSQL na VPS

### ⚡ Opção Rápida: Script Automatizado com Docker

**Execute na VPS:**

```bash
cd /opt/bni-gestao-imobiliaria
./scripts/setup_vps_docker.sh
```

Este script:
- ✅ Verifica e instala Docker se necessário
- ✅ Cria estrutura de diretórios
- ✅ Clona/atualiza repositório
- ✅ Pergunta se quer usar container existente ou criar novo
- ✅ Configura docker-compose.prod.yml
- ✅ Gera senhas seguras
- ✅ Inicia containers
- ✅ Configura ambiente Python
- ✅ Inicializa banco de dados

### Opção A: Usar Container PostgreSQL Existente

**Execute na VPS:**

```bash
# Listar containers PostgreSQL existentes
docker ps | grep postgres

# Escolher um container (exemplo: postgres-fk0kg4gk80k4sowc400wc4sw)
# Criar banco de dados
docker exec -it postgres-fk0kg4gk80k4sowc400wc4sw psql -U postgres -c "CREATE DATABASE bni_gestao;"

# Verificar criação
docker exec -it postgres-fk0kg4gk80k4sowc400wc4sw psql -U postgres -c "\l" | grep bni_gestao
```

### Opção B: Criar Container PostgreSQL Dedicado com Docker Compose

**Execute na VPS:**

```bash
cd /opt/bni-gestao-imobiliaria

# O arquivo docker-compose.prod.yml já está no repositório!
# Criar arquivo .env.prod com senha
cat > .env.prod << EOF
POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
POSTGRES_DB=bni_gestao
POSTGRES_USER=postgres
PGADMIN_EMAIL=admin@bni.local
PGADMIN_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-12)
EOF
chmod 600 .env.prod

# Iniciar containers
docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d

# Verificar status
docker ps | grep bni_postgres_prod
docker-compose -f docker-compose.prod.yml ps
```

## ⚙️ Passo 7: Configurar Variáveis de Ambiente na VPS

**Execute na VPS:**

```bash
cd /opt/bni-gestao-imobiliaria

# Criar .env para produção
cat > .env << EOF
# PostgreSQL
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=bni_gestao
POSTGRES_USER=postgres
POSTGRES_PASSWORD=\$(cat .env.prod | grep POSTGRES_PASSWORD | cut -d'=' -f2)

# Hugging Face
HF_TOKEN=${HF_TOKEN}
HF_DATASET_NAME=senal88/bni-gestao-imobiliaria

# Paths
DATA_RAW_PATH=/opt/bni-gestao-imobiliaria/data/raw
DATA_PROCESSED_PATH=/opt/bni-gestao-imobiliaria/data/processed
DATA_SCHEMAS_PATH=/opt/bni-gestao-imobiliaria/data/schemas

# Logging
LOG_LEVEL=INFO
LOG_FILE=/opt/bni-gestao-imobiliaria/logs/bni_gestao.log
EOF

# Proteger arquivo .env
chmod 600 .env
```

## 🐍 Passo 8: Configurar Python na VPS

**Execute na VPS:**

```bash
cd /opt/bni-gestao-imobiliaria

# Criar ambiente virtual
python3 -m venv venv

# Ativar ambiente virtual
source venv/bin/activate

# Instalar dependências
pip install --upgrade pip
pip install -r requirements.txt

# Verificar instalação
python --version
pip list | grep psycopg2
```

## 🗄️ Passo 9: Inicializar Banco de Dados na VPS

**Execute na VPS:**

```bash
cd /opt/bni-gestao-imobiliaria
source venv/bin/activate

# Inicializar banco de dados
python scripts/init_database.py

# Verificar tabelas criadas
docker exec -it bni_postgres_prod psql -U postgres -d bni_gestao -c "\dt"
```

## 📊 Passo 10: Importar Dados na VPS

**Execute na VPS:**

```bash
cd /opt/bni-gestao-imobiliaria
source venv/bin/activate

# Validar schemas
python scripts/validate_schemas.py

# Importar propriedades
python scripts/import_propriedades.py

# Verificar importação
docker exec -it bni_postgres_prod psql -U postgres -d bni_gestao -c "SELECT COUNT(*) FROM propriedades;"
```

## 🔄 Passo 11: Configurar Sincronização Automática na VPS

**Execute na VPS:**

```bash
cd /opt/bni-gestao-imobiliaria

# Criar script de sincronização
cat > sync_daily.sh << 'EOF'
#!/bin/bash
cd /opt/bni-gestao-imobiliaria
source venv/bin/activate
export $(cat .env | xargs)
python scripts/sync_huggingface.py --push
EOF

chmod +x sync_daily.sh

# Adicionar ao crontab (sincronização diária às 2h)
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/bni-gestao-imobiliaria/sync_daily.sh >> /opt/bni-gestao-imobiliaria/logs/cron.log 2>&1") | crontab -
```

## ✅ Verificar Setup Completo na VPS

**Execute na VPS:**

```bash
# Verificar Docker
docker ps

# Verificar Python
cd /opt/bni-gestao-imobiliaria
source venv/bin/activate
python scripts/init_database.py --validate-only

# Verificar dados
docker exec -it bni_postgres_prod psql -U postgres -d bni_gestao -c "SELECT codigo, nome, valor_avaliacao FROM propriedades LIMIT 5;"

# Verificar estrutura
ls -la /opt/bni-gestao-imobiliaria/
```

## 🔐 Passo 12: Configurar Segurança na VPS

**Execute na VPS:**

```bash
# Criar usuário não-root para aplicação (opcional mas recomendado)
useradd -m -s /bin/bash bni-app
usermod -aG docker bni-app

# Configurar permissões
chown -R bni-app:bni-app /opt/bni-gestao-imobiliaria

# Configurar firewall (se necessário)
# ufw allow 22/tcp
# ufw enable
```

## 📝 Comandos Úteis na VPS

```bash
# Ver logs do PostgreSQL
docker logs bni_postgres_prod

# Reiniciar container PostgreSQL
docker restart bni_postgres_prod

# Backup do banco
docker exec bni_postgres_prod pg_dump -U postgres bni_gestao > backup_$(date +%Y%m%d).sql

# Ver espaço em disco
df -h

# Ver uso de memória
free -h
```

## 🔄 Atualizar Projeto na VPS (após mudanças no GitHub)

**Execute na VPS:**

```bash
cd /opt/bni-gestao-imobiliaria
git pull origin teab
source venv/bin/activate
pip install -r requirements.txt
python scripts/init_database.py  # Se houver mudanças no schema
```

## 📋 Checklist de Setup VPS

- [ ] Docker instalado e rodando
- [ ] PostgreSQL container criado/identificado
- [ ] Repositório clonado em `/opt/bni-gestao-imobiliaria`
- [ ] Ambiente virtual Python criado
- [ ] Dependências instaladas
- [ ] Banco de dados inicializado
- [ ] Dados importados
- [ ] Crontab configurado (opcional)
- [ ] Logs funcionando

## 🔗 Próximos Passos

- Configurar GitHub Actions para deploy automático: [`CONFIGURACAO_DEPLOY.md`](CONFIGURACAO_DEPLOY.md)
- Documentação de deploy: [`CONFIGURACAO_PERSONALIZADA.md`](CONFIGURACAO_PERSONALIZADA.md)

