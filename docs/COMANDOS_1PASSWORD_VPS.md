# 📋 Comandos Prontos - Setup 1Password VPS

Todos os comandos prontos para copiar e colar. Execute na ordem indicada.

## 🍎 PASSO 1: No Mac - Criar Itens no 1Password

```bash
# No Mac - Criar todos os itens necessários
cd ~/bni-gestao-imobiliaria
chmod +x scripts/criar_itens_1p_mac.sh
./scripts/criar_itens_1p_mac.sh
```

**OU criar manualmente:**

```bash
# Autenticar no 1Password
op signin

# Criar PostgreSQL VPS
op item create \
  --vault "1p_vps" \
  --category "Database" \
  --title "BNI Gestão - PostgreSQL Vps" \
  --field "hostname=localhost" \
  --field "database=bni_gestao" \
  --field "username=postgres" \
  --field "password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)" \
  --field "port=5432"

# Criar Hugging Face Token
op item create \
  --vault "1p_vps" \
  --category "API Credential" \
  --title "BNI Gestão - Hugging Face Token" \
  --field "credential=seu_token_huggingface_aqui" \
  --field "dataset=senal88/bni-gestao-imobiliaria"

# Verificar itens criados
op item list --vault "1p_vps"
```

## 🖥️ PASSO 2: Na VPS - Instalar 1Password CLI

```bash
# Conectar na VPS
ssh vps

# Clonar repositório
mkdir -p /opt/bni-gestao-imobiliaria
cd /opt/bni-gestao-imobiliaria
git clone https://github.com/senal88/bni-gestao-imobiliaria.git .

# Instalar 1Password CLI
chmod +x scripts/install_1password_vps.sh
./scripts/install_1password_vps.sh
```

## 🔐 PASSO 3: Na VPS - Autenticar no 1Password

```bash
# Na VPS - Autenticar (primeira vez)
op signin

# Verificar autenticação
op account list
op vault list

# Verificar acesso ao vault 1p_vps
op item list --vault "1p_vps"
```

## 🚀 PASSO 4: Na VPS - Setup Completo Automatizado

```bash
# Na VPS - Executar setup completo
cd /opt/bni-gestao-imobiliaria
chmod +x scripts/setup_vps_completo_1p.sh
./scripts/setup_vps_completo_1p.sh
```

Este script faz TUDO automaticamente:
- ✅ Verifica/cria itens no 1Password
- ✅ Carrega secrets automaticamente
- ✅ Configura Docker
- ✅ Inicia containers PostgreSQL
- ✅ Configura ambiente Python
- ✅ Inicializa banco de dados

## 📊 PASSO 5: Na VPS - Importar Dados

```bash
# Na VPS - Carregar secrets e importar dados
cd /opt/bni-gestao-imobiliaria

# Carregar secrets do 1Password
./scripts/load_secrets_1p.sh

# Ativar ambiente Python
source venv/bin/activate

# Importar propriedades
python scripts/import_propriedades.py

# Verificar importação
docker exec bni_postgres_prod psql -U postgres -d bni_gestao -c "SELECT COUNT(*) FROM propriedades;"
```

## 🔄 Comandos de Uso Diário

### Recarregar Secrets

```bash
# Na VPS
cd /opt/bni-gestao-imobiliaria
./scripts/load_secrets_1p.sh
```

### Ver Secrets do 1Password

```bash
# Ver item PostgreSQL
op item get "BNI Gestão - PostgreSQL Vps" --vault "1p_vps"

# Ver senha apenas
op item get "BNI Gestão - PostgreSQL Vps" --vault "1p_vps" --fields "password"

# Ver token Hugging Face
op item get "BNI Gestão - Hugging Face Token" --vault "1p_vps" --fields "credential"
```

### Atualizar Secrets

```bash
# Atualizar senha PostgreSQL
op item edit "BNI Gestão - PostgreSQL Vps" \
  --vault "1p_vps" \
  password="nova_senha_aqui"

# Atualizar token Hugging Face
op item edit "BNI Gestão - Hugging Face Token" \
  --vault "1p_vps" \
  credential="novo_token_aqui"

# Recarregar após atualizar
cd /opt/bni-gestao-imobiliaria
./scripts/load_secrets_1p.sh
```

## 🔧 Troubleshooting Rápido

### Reautenticar

```bash
op signin
```

### Verificar Vaults

```bash
op vault list
```

### Verificar Itens

```bash
op item list --vault "1p_vps"
```

### Testar Conexão

```bash
# Testar se consegue ler secrets
op item get "BNI Gestão - PostgreSQL Vps" --vault "1p_vps" --fields "password"
```

## 📝 Checklist Completo

Execute na ordem:

- [ ] **No Mac**: Criar itens no 1Password (`./scripts/criar_itens_1p_mac.sh`)
- [ ] **Na VPS**: Instalar 1Password CLI (`./scripts/install_1password_vps.sh`)
- [ ] **Na VPS**: Autenticar (`op signin`)
- [ ] **Na VPS**: Setup completo (`./scripts/setup_vps_completo_1p.sh`)
- [ ] **Na VPS**: Importar dados (`python scripts/import_propriedades.py`)
- [ ] **Verificar**: Containers rodando (`docker ps | grep bni_`)

## 🎯 Comando Único (Após Preparar 1Password)

Se já criou os itens no 1Password, execute tudo de uma vez:

```bash
# Na VPS
ssh vps << 'EOF'
mkdir -p /opt/bni-gestao-imobiliaria
cd /opt/bni-gestao-imobiliaria
git clone https://github.com/senal88/bni-gestao-imobiliaria.git .
chmod +x scripts/*.sh
./scripts/install_1password_vps.sh
op signin  # Autenticar manualmente
./scripts/setup_vps_completo_1p.sh
EOF
```

