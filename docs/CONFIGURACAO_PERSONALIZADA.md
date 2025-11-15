# ⚡ Configuração Personalizada - Seu Ambiente

Este documento contém as configurações específicas do seu ambiente.

## 🔑 Informações SSH

### Configuração Atual ✅

- **Chave SSH**: `~/.ssh/id_ed25519_universal`
- **Host VPS**: `vps` (alias configurado em `~/.ssh/config`)
- **IP VPS**: `147.79.81.59`
- **Usuário VPS**: `root`
- **Porta SSH**: `22`
- **Status**: ✅ Acesso SSH funcionando (`ssh vps` funciona)

### Comando para Obter Chave Privada (GitHub Secret)

```bash
cat ~/.ssh/id_ed25519_universal
```

Copie toda a saída (incluindo `-----BEGIN OPENSSH PRIVATE KEY-----` e `-----END OPENSSH PRIVATE KEY-----`) e cole no GitHub Secret `SSH_PRIVATE_KEY`.

## 🗄️ PostgreSQL no VPS

### Containers PostgreSQL Disponíveis

Execute no VPS para identificar:

```bash
ssh vps "docker ps | grep postgres"
```

Você verá algo como:
```
82b9e7c45d0c   ghcr.io/fazer-ai/postgres-16-pgvector:latest   ...   5432/tcp   postgres-fk0kg4gk80k4sowc400wc4sw
ad75aa3c31f6   postgres:16-alpine                             ...   5432/tcp   postgresql-iccg8w0w8kg0s0ok8408o0gc
405d157abb79   postgres:15-alpine                             ...   5432/tcp   coolify-db
```

### Escolher Container PostgreSQL

**Opção 1: Usar container existente (recomendado)**

Escolha um dos containers acima e configure:

```bash
# Exemplo: usar postgres-fk0kg4gk80k4sowc400wc4sw
ssh vps << 'EOF'
docker exec -it postgres-fk0kg4gk80k4sowc400wc4sw psql -U postgres -c "CREATE DATABASE bni_gestao;"
EOF
```

**Configuração GitHub Secrets:**
- `POSTGRES_HOST`: `localhost` (ou nome do container se acessar de dentro do VPS)
- `POSTGRES_PORT`: `5432`
- `POSTGRES_DB`: `bni_gestao`
- `POSTGRES_USER`: `postgres` (ou usuário do container)
- `POSTGRES_PASSWORD`: `<senha_do_container>`

**Opção 2: Criar container dedicado**

```bash
ssh vps << 'EOF'
mkdir -p /opt/bni-gestao-imobiliaria/docker
cd /opt/bni-gestao-imobiliaria/docker

cat > docker-compose.yml << 'COMPOSE'
version: '3.8'
services:
  postgres:
    image: postgres:14-alpine
    container_name: bni_postgres
    environment:
      POSTGRES_DB: bni_gestao
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: sua_senha_segura_aqui
    ports:
      - "5433:5432"  # Porta diferente para não conflitar
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ../scripts/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    restart: unless-stopped

volumes:
  postgres_data:
COMPOSE

docker-compose up -d
EOF
```

## 📋 Checklist de Secrets do GitHub

Acesse: `https://github.com/senal88/bni-gestao-imobiliaria/settings/secrets/actions`

### SSH (4 secrets)

- [ ] **`SSH_PRIVATE_KEY`**
  ```bash
  cat ~/.ssh/id_ed25519_universal
  ```

- [ ] **`SSH_HOST`**: `147.79.81.59`

- [ ] **`SSH_USER`**: `root`

- [ ] **`SSH_PORT`**: `22`

### PostgreSQL (5 secrets)

- [ ] **`POSTGRES_HOST`**: `localhost` (ou nome do container)

- [ ] **`POSTGRES_PORT`**: `5432` (ou `5433` se usar container dedicado)

- [ ] **`POSTGRES_DB`**: `bni_gestao`

- [ ] **`POSTGRES_USER`**: `postgres`

- [ ] **`POSTGRES_PASSWORD`**: `<sua_senha>`

### Hugging Face (2 secrets - opcional)

- [ ] **`HF_TOKEN`**: Obter em https://huggingface.co/settings/tokens

- [ ] **`HF_DATASET_NAME`**: `senal88/bni-gestao-imobiliaria`

## 🚀 Comandos de Teste

### 1. Testar SSH

```bash
ssh vps "echo 'SSH OK'"
```

### 2. Preparar VPS

```bash
ssh vps << 'EOF'
mkdir -p /opt/bni-gestao-imobiliaria
cd /opt/bni-gestao-imobiliaria
git clone https://github.com/senal88/bni-gestao-imobiliaria.git .
EOF
```

### 3. Identificar PostgreSQL

```bash
ssh vps "./scripts/identificar_postgres.sh"
```

### 4. Testar Deploy Manual

```bash
ssh vps << 'EOF'
cd /opt/bni-gestao-imobiliaria
python3 -m pip install -r requirements.txt --quiet
export POSTGRES_HOST=localhost
export POSTGRES_PORT=5432
export POSTGRES_DB=bni_gestao
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=sua_senha
python3 scripts/init_database.py
EOF
```

## 📝 Próximos Passos

1. ✅ SSH já configurado
2. ⏳ Identificar/Configurar PostgreSQL no VPS
3. ⏳ Configurar Secrets no GitHub
4. ⏳ Testar deploy manual
5. ⏳ Fazer push e verificar GitHub Actions

## 🔗 Referências

- [Guia Completo de Deploy](CONFIGURACAO_DEPLOY.md)
- [Resumo Rápido](RESUMO_CONFIGURACAO.md)

