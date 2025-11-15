# 🚀 Guia de Configuração de Deploy - VPS PostgreSQL

Este guia explica como configurar o deploy automático do projeto BNI Gestão Imobiliária no VPS usando GitHub Actions.

## 📋 Pré-requisitos

- ✅ Acesso SSH ao VPS (hostname: `senamfo`, usuário: `root`)
- ✅ Repositório GitHub criado: `senal88/bni-gestao-imobiliaria`
- ✅ PostgreSQL rodando no VPS (já configurado via Docker)

## 🔧 Passo 1: Preparar o VPS

### 1.1 Criar diretório de deploy

```bash
ssh vps
mkdir -p /opt/bni-gestao-imobiliaria
cd /opt/bni-gestao-imobiliaria
```

### 1.2 Clonar o repositório no VPS

```bash
# Se ainda não clonou
git clone https://github.com/senal88/bni-gestao-imobiliaria.git /opt/bni-gestao-imobiliaria
cd /opt/bni-gestao-imobiliaria
```

### 1.3 Criar usuário dedicado (opcional, mas recomendado)

```bash
# Criar usuário para deploy
useradd -m -s /bin/bash bni-deploy
usermod -aG docker bni-deploy

# Criar diretório home
mkdir -p /home/bni-deploy/.ssh
chown -R bni-deploy:bni-deploy /home/bni-deploy
```

### 1.4 Configurar PostgreSQL no VPS

Verifique qual container PostgreSQL está rodando:

```bash
docker ps | grep postgres
```

Identifique o container PostgreSQL que será usado. Você pode usar um existente ou criar um novo.

## 🔑 Passo 2: Configurar SSH Key para GitHub Actions

### 2.1 Usar chave SSH existente

Você já tem uma chave SSH configurada (`~/.ssh/id_ed25519_universal`) e acesso ao VPS funcionando.

**Opção A: Usar chave existente (recomendado)**

```bash
# Verificar se a chave pública já está no VPS
ssh vps "grep -q '$(cat ~/.ssh/id_ed25519_universal.pub | cut -d' ' -f2)' ~/.ssh/authorized_keys && echo 'Chave já configurada' || echo 'Chave não encontrada'"

# Se não estiver, adicionar:
cat ~/.ssh/id_ed25519_universal.pub | ssh vps "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

**Opção B: Criar chave dedicada para GitHub Actions**

```bash
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/bni_deploy_key
cat ~/.ssh/bni_deploy_key.pub | ssh vps "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### 2.2 Testar conexão SSH

```bash
# Com sua configuração atual (já deve funcionar)
ssh vps "echo 'SSH funcionando!'"

# Se usar chave dedicada:
ssh -i ~/.ssh/bni_deploy_key -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@147.79.81.59 "echo 'SSH funcionando!'"
```

## 🔐 Passo 3: Configurar Secrets no GitHub

Acesse: `https://github.com/senal88/bni-gestao-imobiliaria/settings/secrets/actions`

### Secrets Necessários:

#### SSH Configuration
- **`SSH_PRIVATE_KEY`**: Conteúdo completo da chave privada
  ```bash
  # Opção A: Usar chave existente
  cat ~/.ssh/id_ed25519_universal

  # Opção B: Se criou chave dedicada
  cat ~/.ssh/bni_deploy_key
  ```
- **`SSH_HOST`**: IP do VPS: `147.79.81.59` (ou hostname se configurado no GitHub Actions)
- **`SSH_USER`**: Usuário SSH: `root`
- **`SSH_PORT`**: Porta SSH: `22` (padrão)

#### PostgreSQL Configuration
- **`POSTGRES_HOST`**: Host do PostgreSQL
  - Se usar container Docker: nome do container ou `localhost`
  - Exemplo: `postgres-fk0kg4gk80k4sowc400wc4sw` ou `localhost`
- **`POSTGRES_PORT`**: Porta do PostgreSQL (geralmente `5432`)
- **`POSTGRES_DB`**: Nome do banco (ex: `bni_gestao`)
- **`POSTGRES_USER`**: Usuário do PostgreSQL (ex: `postgres`)
- **`POSTGRES_PASSWORD`**: Senha do PostgreSQL

#### Hugging Face (opcional, para sync)
- **`HF_TOKEN`**: Token do Hugging Face
  ```bash
  # Obter token em: https://huggingface.co/settings/tokens
  ```
- **`HF_DATASET_NAME`**: Nome do dataset (ex: `senal88/bni-gestao-imobiliaria`)

## 📝 Passo 4: Identificar Container PostgreSQL

No seu VPS, execute:

```bash
docker ps | grep postgres
```

Você verá algo como:
```
82b9e7c45d0c   ghcr.io/fazer-ai/postgres-16-pgvector:latest   ...   5432/tcp   postgres-fk0kg4gk80k4sowc400wc4sw
```

### Opções de Conexão:

#### Opção A: Usar container existente (recomendado se já tem PostgreSQL)

1. **Conectar ao container PostgreSQL existente:**
   ```bash
   docker exec -it postgres-fk0kg4gk80k4sowc400wc4sw psql -U postgres
   ```

2. **Criar banco de dados:**
   ```sql
   CREATE DATABASE bni_gestao;
   \q
   ```

3. **Configurar secrets:**
   - `POSTGRES_HOST`: `localhost` (se acessar de dentro do VPS)
   - `POSTGRES_PORT`: `5432`
   - `POSTGRES_DB`: `bni_gestao`
   - `POSTGRES_USER`: `postgres`
   - `POSTGRES_PASSWORD`: (senha do container)

#### Opção B: Criar novo container PostgreSQL dedicado

1. **Criar docker-compose dedicado no VPS:**
   ```bash
   mkdir -p /opt/bni-gestao-imobiliaria/docker
   cd /opt/bni-gestao-imobiliaria/docker
   ```

2. **Criar `docker-compose.yml`:**
   ```yaml
   version: '3.8'
   services:
     postgres:
       image: postgres:14-alpine
       container_name: bni_postgres
       environment:
         POSTGRES_DB: bni_gestao
         POSTGRES_USER: postgres
         POSTGRES_PASSWORD: sua_senha_aqui
       ports:
         - "5433:5432"  # Porta diferente para não conflitar
       volumes:
         - postgres_data:/var/lib/postgresql/data
         - ../scripts/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
       restart: unless-stopped

   volumes:
     postgres_data:
   ```

3. **Iniciar container:**
   ```bash
   docker-compose up -d
   ```

## ✅ Passo 5: Testar Deploy Manual

Antes de configurar o GitHub Actions, teste manualmente:

```bash
# No seu Mac
cd ~/bni-gestao-imobiliaria

# Testar conexão SSH (com sua configuração atual)
ssh vps "cd /opt/bni-gestao-imobiliaria && pwd"

# Testar inicialização do banco (via SSH)
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

## 🎯 Passo 6: Configurar GitHub Actions

Após configurar todos os secrets, o workflow será executado automaticamente quando:

1. Fazer push para `main` ou `master`
2. Alterar arquivos em `scripts/` ou `data/schemas/`
3. Executar manualmente via `workflow_dispatch`

### Verificar execução:

Acesse: `https://github.com/senal88/bni-gestao-imobiliaria/actions`

## 🔍 Troubleshooting

### Erro: "Permission denied (publickey)"

- Verifique se a chave privada foi copiada corretamente no GitHub Secret
- Verifique se a chave pública está no `~/.ssh/authorized_keys` do VPS:
  ```bash
  ssh vps "cat ~/.ssh/authorized_keys"
  ```
- Teste conexão manual:
  ```bash
  ssh vps "echo 'OK'"
  # Ou com IP direto:
  ssh -i ~/.ssh/id_ed25519_universal root@147.79.81.59 "echo 'OK'"
  ```

### Erro: "Connection refused" no PostgreSQL

- Verifique se o container PostgreSQL está rodando: `docker ps | grep postgres`
- Verifique se a porta está correta
- Teste conexão: `docker exec -it <container> psql -U postgres`

### Erro: "Database does not exist"

- Crie o banco manualmente:
  ```bash
  docker exec -it <postgres_container> psql -U postgres -c "CREATE DATABASE bni_gestao;"
  ```

### Erro: "Command not found: python3"

- Instale Python 3 no VPS:
  ```bash
  apt update && apt install -y python3 python3-pip
  ```

## 📚 Referências

- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [SSH Key Setup](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [PostgreSQL Docker](https://hub.docker.com/_/postgres)

