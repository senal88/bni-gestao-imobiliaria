# 🔐 Integração com 1Password

Guia para usar 1Password para gerenciar secrets e credenciais do projeto BNI Gestão Imobiliária.

## 📋 Vaults Disponíveis

Você tem os seguintes vaults configurados:
- `1p_macos` - Para uso no Mac
- `1p_vps` - Para uso na VPS
- `default importado`
- `Personal`

## 🍎 No macOS (Desenvolvimento Local)

### Configurar 1Password CLI no Mac

```bash
# Verificar se 1Password CLI está instalado
op --version

# Se não estiver, instalar via Homebrew
brew install --cask 1password-cli

# Autenticar
op signin
```

### Criar Item no 1Password para BNI Gestão

**No Mac, execute:**

```bash
# Criar item no vault 1p_macos
op item create \
  --vault "1p_macos" \
  --category "Database" \
  --title "BNI Gestão - PostgreSQL Local" \
  --field "hostname=localhost" \
  --field "database=bni_gestao" \
  --field "username=postgres" \
  --field "password=postgres" \
  --field "port=5432"

# Criar item para Hugging Face
op item create \
  --vault "1p_macos" \
  --category "API Credential" \
  --title "BNI Gestão - Hugging Face Token" \
  --field "credential=seu_token_hf_aqui" \
  --field "dataset=senal88/bni-gestao-imobiliaria"
```

### Usar Secrets do 1Password no Mac

**Opção 1: Carregar no .env automaticamente**

```bash
# Criar script helper
cat > scripts/load_secrets_1p.sh << 'EOF'
#!/bin/bash
# Carrega secrets do 1Password para .env

eval $(op signin)

# PostgreSQL
POSTGRES_PASSWORD=$(op item get "BNI Gestão - PostgreSQL Local" --vault "1p_macos" --fields "password" 2>/dev/null || echo "postgres")
POSTGRES_USER=$(op item get "BNI Gestão - PostgreSQL Local" --vault "1p_macos" --fields "username" 2>/dev/null || echo "postgres")
POSTGRES_DB=$(op item get "BNI Gestão - PostgreSQL Local" --vault "1p_macos" --fields "database" 2>/dev/null || echo "bni_gestao")

# Hugging Face
HF_TOKEN=$(op item get "BNI Gestão - Hugging Face Token" --vault "1p_macos" --fields "credential" 2>/dev/null || echo "")

# Gerar .env
cat > .env << ENVEOF
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=${POSTGRES_DB}
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

HF_TOKEN=${HF_TOKEN}
HF_DATASET_NAME=senal88/bni-gestao-imobiliaria

DATA_RAW_PATH=./data/raw
DATA_PROCESSED_PATH=./data/processed
DATA_SCHEMAS_PATH=./data/schemas

LOG_LEVEL=INFO
LOG_FILE=./logs/bni_gestao.log
ENVEOF

chmod 600 .env
echo "✅ .env criado com secrets do 1Password"
EOF

chmod +x scripts/load_secrets_1p.sh
```

**Opção 2: Usar diretamente em scripts**

```bash
# Exemplo: usar token do Hugging Face diretamente
HF_TOKEN=$(op item get "BNI Gestão - Hugging Face Token" --vault "1p_macos" --fields "credential")
python scripts/sync_huggingface.py --push
```

## 🖥️ Na VPS (Produção)

### Configurar 1Password CLI na VPS

**Na VPS, execute:**

```bash
# Instalar 1Password CLI
curl -sSf https://downloads.1password.com/linux/keys/1password.asc | \
  gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | \
  tee /etc/apt/sources.list.d/1password.list

apt update && apt install -y 1password-cli

# Autenticar (use o vault 1p_vps)
op signin
```

### Criar Item no 1Password para VPS

**No Mac ou VPS:**

```bash
# Criar item no vault 1p_vps
op item create \
  --vault "1p_vps" \
  --category "Database" \
  --title "BNI Gestão - PostgreSQL VPS" \
  --field "hostname=localhost" \
  --field "database=bni_gestao" \
  --field "username=postgres" \
  --field "password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)" \
  --field "port=5432" \
  --field "container=bni_postgres_prod"

# Criar item para SSH (se necessário)
op item create \
  --vault "1p_vps" \
  --category "SSH Key" \
  --title "BNI Gestão - SSH Deploy Key" \
  --field "private_key=$(cat ~/.ssh/id_ed25519_universal)" \
  --field "host=147.79.81.59" \
  --field "user=root"
```

### Usar Secrets do 1Password na VPS

**Na VPS:**

```bash
# Criar script para carregar secrets
cat > /opt/bni-gestao-imobiliaria/scripts/load_secrets_1p.sh << 'EOF'
#!/bin/bash
# Carrega secrets do 1Password para .env na VPS

eval $(op signin)

# PostgreSQL
POSTGRES_PASSWORD=$(op item get "BNI Gestão - PostgreSQL VPS" --vault "1p_vps" --fields "password" 2>/dev/null)
POSTGRES_USER=$(op item get "BNI Gestão - PostgreSQL VPS" --vault "1p_vps" --fields "username" 2>/dev/null || echo "postgres")
POSTGRES_DB=$(op item get "BNI Gestão - PostgreSQL VPS" --vault "1p_vps" --fields "database" 2>/dev/null || echo "bni_gestao")

# Hugging Face
HF_TOKEN=$(op item get "BNI Gestão - Hugging Face Token" --vault "1p_vps" --fields "credential" 2>/dev/null)

# Gerar .env
cat > .env << ENVEOF
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=${POSTGRES_DB}
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

HF_TOKEN=${HF_TOKEN}
HF_DATASET_NAME=senal88/bni-gestao-imobiliaria

DATA_RAW_PATH=/opt/bni-gestao-imobiliaria/data/raw
DATA_PROCESSED_PATH=/opt/bni-gestao-imobiliaria/data/processed
DATA_SCHEMAS_PATH=/opt/bni-gestao-imobiliaria/data/schemas

LOG_LEVEL=INFO
LOG_FILE=/opt/bni-gestao-imobiliaria/logs/bni_gestao.log
ENVEOF

chmod 600 .env
echo "✅ .env criado com secrets do 1Password"
EOF

chmod +x /opt/bni-gestao-imobiliaria/scripts/load_secrets_1p.sh
```

## 🔄 Integração com GitHub Actions

### Usar 1Password para GitHub Secrets

**No Mac:**

```bash
# Obter secrets do 1Password e configurar no GitHub
# SSH Private Key
op item get "BNI Gestão - SSH Deploy Key" --vault "1p_vps" --fields "private_key" | \
  gh secret set SSH_PRIVATE_KEY

# PostgreSQL
op item get "BNI Gestão - PostgreSQL VPS" --vault "1p_vps" --fields "password" | \
  gh secret set POSTGRES_PASSWORD

op item get "BNI Gestão - PostgreSQL VPS" --vault "1p_vps" --fields "username" | \
  gh secret set POSTGRES_USER

# Hugging Face
op item get "BNI Gestão - Hugging Face Token" --vault "1p_vps" --fields "credential" | \
  gh secret set HF_TOKEN
```

## 📝 Estrutura Recomendada de Itens no 1Password

### Vault: `1p_macos` (Desenvolvimento Local)

1. **BNI Gestão - PostgreSQL Local**
   - hostname: localhost
   - database: bni_gestao
   - username: postgres
   - password: postgres
   - port: 5432

2. **BNI Gestão - Hugging Face Token**
   - credential: [seu token]
   - dataset: senal88/bni-gestao-imobiliaria

### Vault: `1p_vps` (Produção)

1. **BNI Gestão - PostgreSQL VPS**
   - hostname: localhost
   - database: bni_gestao
   - username: postgres
   - password: [senha gerada]
   - port: 5432
   - container: bni_postgres_prod

2. **BNI Gestão - SSH Deploy Key**
   - private_key: [chave SSH privada]
   - host: 147.79.81.59
   - user: root
   - port: 22

3. **BNI Gestão - Hugging Face Token**
   - credential: [seu token]
   - dataset: senal88/bni-gestao-imobiliaria

4. **BNI Gestão - GitHub Secrets** (referência)
   - SSH_PRIVATE_KEY: [referência ao SSH Deploy Key]
   - POSTGRES_HOST: 147.79.81.59
   - POSTGRES_PORT: 5432
   - POSTGRES_DB: bni_gestao
   - POSTGRES_USER: postgres
   - POSTGRES_PASSWORD: [referência ao PostgreSQL VPS]
   - HF_TOKEN: [referência ao Hugging Face Token]

## 🔧 Scripts Úteis

### Atualizar Makefile para usar 1Password

```makefile
# Adicionar ao Makefile
load-secrets-1p: ## Carrega secrets do 1Password para .env
	@echo "Carregando secrets do 1Password..."
	@./scripts/load_secrets_1p.sh

sync-hf-1p: load-secrets-1p ## Sincroniza com Hugging Face usando 1Password
	@echo "Sincronizando com Hugging Face..."
	@python scripts/sync_huggingface.py --push
```

## 🔒 Segurança

### Boas Práticas

- ✅ Nunca commitar arquivos `.env` no Git
- ✅ Usar vaults separados para Mac e VPS
- ✅ Rotacionar senhas periodicamente
- ✅ Usar senhas geradas aleatoriamente
- ✅ Limitar acesso aos vaults do 1Password

### Verificar .gitignore

Certifique-se de que `.gitignore` inclui:

```
.env
.env.*
*.key
*.pem
secrets/
```

## 📚 Comandos Úteis do 1Password CLI

```bash
# Listar itens
op item list --vault "1p_macos"

# Obter item específico
op item get "BNI Gestão - PostgreSQL Local" --vault "1p_vps"

# Obter campo específico
op item get "BNI Gestão - PostgreSQL Local" --vault "1p_vps" --fields "password"

# Criar item via JSON
op item create --vault "1p_vps" < item.json

# Atualizar item
op item edit "BNI Gestão - PostgreSQL Local" --vault "1p_vps" password="nova_senha"

# Deletar item
op item delete "BNI Gestão - PostgreSQL Local" --vault "1p_vps"
```

## 🔗 Referências

- [1Password CLI Documentation](https://developer.1password.com/docs/cli)
- [1Password CLI GitHub](https://github.com/1Password/1password-cli)

