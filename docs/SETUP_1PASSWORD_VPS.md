# 🔐 Setup Completo com 1Password na VPS

Guia passo a passo para instalar, configurar e automatizar o 1Password CLI na VPS **sem precisar digitar senhas manualmente**.

> ⚡ **Quer comandos prontos para copiar?** Veja [`COMANDOS_1PASSWORD_VPS.md`](COMANDOS_1PASSWORD_VPS.md)

## 📋 Pré-requisitos

- ✅ Acesso SSH à VPS (`ssh vps`)
- ✅ 1Password app instalado no Mac
- ✅ Vault `1p_vps` criado no 1Password
- ✅ Conta 1Password configurada

## 🚀 Setup Rápido (Recomendado)

### Passo 1: Preparar Secrets no Mac

**No seu Mac, execute:**

```bash
# Autenticar no 1Password (se ainda não fez)
op signin

# Criar item PostgreSQL VPS no vault 1p_vps
op item create \
  --vault "1p_vps" \
  --category "Database" \
  --title "BNI Gestão - PostgreSQL Vps" \
  --field "hostname=localhost" \
  --field "database=bni_gestao" \
  --field "username=postgres" \
  --field "password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)" \
  --field "port=5432"

# Criar item Hugging Face Token
op item create \
  --vault "1p_vps" \
  --category "API Credential" \
  --title "BNI Gestão - Hugging Face Token" \
  --field "credential=seu_token_huggingface_aqui" \
  --field "dataset=senal88/bni-gestao-imobiliaria"

# Verificar itens criados
op item list --vault "1p_vps"
```

### Passo 2: Conectar na VPS

**No seu Mac:**

```bash
ssh vps
```

### Passo 3: Instalar 1Password CLI na VPS

**Na VPS:**

```bash
# Clonar repositório primeiro
mkdir -p /opt/bni-gestao-imobiliaria
cd /opt/bni-gestao-imobiliaria
git clone https://github.com/senal88/bni-gestao-imobiliaria.git .

# Executar script de instalação
chmod +x scripts/install_1password_vps.sh
./scripts/install_1password_vps.sh
```

### Passo 4: Autenticar na VPS

**Na VPS, você tem duas opções:**

#### Opção A: Autenticação Manual (Primeira Vez)

```bash
# Autenticar manualmente (vai pedir senha do 1Password)
op signin

# Verificar autenticação
op account list
op vault list
```

#### Opção B: Autenticação via SSH Agent (Automática)

**No Mac, configure SSH Agent:**

```bash
# Adicionar ao ~/.ssh/config
cat >> ~/.ssh/config << 'EOF'

Host vps
    ForwardAgent yes
EOF

# Reiniciar SSH
ssh-add -K ~/.ssh/id_ed25519_universal
```

**Na VPS, usar autenticação automática:**

```bash
# O 1Password CLI vai usar a autenticação do Mac via SSH Agent
op signin --account sua-conta-1password
```

### Passo 5: Setup Completo Automatizado

**Na VPS:**

```bash
cd /opt/bni-gestao-imobiliaria

# Executar setup completo que usa 1Password
chmod +x scripts/setup_vps_completo_1p.sh
./scripts/setup_vps_completo_1p.sh
```

Este script:
- ✅ Verifica/cria itens no 1Password
- ✅ Carrega secrets automaticamente
- ✅ Configura Docker
- ✅ Inicia containers PostgreSQL
- ✅ Configura ambiente Python
- ✅ Inicializa banco de dados

## 🔄 Automação Completa

### Criar Script de Autenticação Automática

**Na VPS:**

```bash
cat > /opt/bni-gestao-imobiliaria/scripts/auth_1p.sh << 'EOF'
#!/bin/bash
# Script de autenticação automática no 1Password

# Verificar se já está autenticado
if op account list &> /dev/null 2>&1; then
    echo "✅ Já autenticado no 1Password"
    exit 0
fi

# Tentar autenticar
echo "🔐 Autenticando no 1Password..."
op signin --account sua-conta-1password --raw || {
    echo "⚠️  Autenticação falhou. Execute manualmente: op signin"
    exit 1
}

echo "✅ Autenticação concluída"
EOF

chmod +x /opt/bni-gestao-imobiliaria/scripts/auth_1p.sh
```

### Usar em Scripts

**Na VPS:**

```bash
# Sempre que precisar usar secrets, autenticar primeiro
source /opt/bni-gestao-imobiliaria/scripts/auth_1p.sh

# Depois carregar secrets
cd /opt/bni-gestao-imobiliaria
./scripts/load_secrets_1p.sh
```

## 🔐 Gerenciar Secrets

### Ver Secrets

```bash
# Listar todos os itens do vault
op item list --vault "1p_vps"

# Ver item específico
op item get "BNI Gestão - PostgreSQL Vps" --vault "1p_vps"

# Obter campo específico
op item get "BNI Gestão - PostgreSQL Vps" --vault "1p_vps" --fields "password"
```

### Atualizar Secrets

```bash
# Atualizar senha do PostgreSQL
op item edit "BNI Gestão - PostgreSQL Vps" \
  --vault "1p_vps" \
  password="nova_senha_aqui"

# Atualizar token do Hugging Face
op item edit "BNI Gestão - Hugging Face Token" \
  --vault "1p_vps" \
  credential="novo_token_aqui"

# Recarregar secrets após atualizar
cd /opt/bni-gestao-imobiliaria
./scripts/load_secrets_1p.sh
```

### Criar Novos Secrets

```bash
# Exemplo: criar secret para API externa
op item create \
  --vault "1p_vps" \
  --category "API Credential" \
  --title "BNI Gestão - API Externa" \
  --field "api_key=sua_chave_aqui" \
  --field "endpoint=https://api.exemplo.com"
```

## 🔄 Integração com Cron Jobs

### Configurar Sincronização Automática

**Na VPS:**

```bash
# Criar script de sincronização que usa 1Password
cat > /opt/bni-gestao-imobiliaria/scripts/sync_daily_1p.sh << 'EOF'
#!/bin/bash
# Sincronização diária usando secrets do 1Password

cd /opt/bni-gestao-imobiliaria

# Autenticar
source scripts/auth_1p.sh

# Carregar secrets
./scripts/load_secrets_1p.sh

# Ativar ambiente Python
source venv/bin/activate

# Carregar variáveis de ambiente
export $(cat .env | grep -v '^#' | xargs)

# Sincronizar com Hugging Face
python scripts/sync_huggingface.py --push

echo "✅ Sincronização concluída em $(date)"
EOF

chmod +x /opt/bni-gestao-imobiliaria/scripts/sync_daily_1p.sh

# Adicionar ao crontab (executa diariamente às 2h)
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/bni-gestao-imobiliaria/scripts/sync_daily_1p.sh >> /opt/bni-gestao-imobiliaria/logs/cron.log 2>&1") | crontab -
```

## 🔒 Segurança

### Verificar Permissões

```bash
# Verificar permissões dos scripts
ls -la /opt/bni-gestao-imobiliaria/scripts/*.sh

# Verificar permissões do .env
ls -la /opt/bni-gestao-imobiliaria/.env
# Deve mostrar: -rw------- (600)
```

### Rotacionar Senhas

```bash
# Gerar nova senha
NEW_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

# Atualizar no 1Password
op item edit "BNI Gestão - PostgreSQL Vps" \
  --vault "1p_vps" \
  password="$NEW_PASSWORD"

# Atualizar no Docker (se usando container dedicado)
cd /opt/bni-gestao-imobiliaria
docker-compose -f docker-compose.prod.yml down
# Atualizar .env.prod com nova senha
./scripts/load_secrets_1p.sh
docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d
```

## 🐛 Troubleshooting

### Erro: "Not signed in"

```bash
# Autenticar novamente
op signin

# Verificar autenticação
op account list
```

### Erro: "Vault not found"

```bash
# Listar vaults disponíveis
op vault list

# Se 1p_vps não existir, criar no Mac primeiro
# Depois sincronizar na VPS
op sync
```

### Erro: "Item not found"

```bash
# Listar itens do vault
op item list --vault "1p_vps"

# Verificar nome exato do item
# O script espera: "BNI Gestão - PostgreSQL Vps" (com "Vps" capitalizado)
```

### Autenticação Expira

```bash
# Reautenticar
op signin

# Ou usar script de autenticação automática
./scripts/auth_1p.sh
```

## 📋 Checklist Completo

- [ ] 1Password app instalado no Mac
- [ ] Vault `1p_vps` criado no 1Password
- [ ] Itens criados no vault `1p_vps`:
  - [ ] BNI Gestão - PostgreSQL Vps
  - [ ] BNI Gestão - Hugging Face Token
- [ ] 1Password CLI instalado na VPS
- [ ] Autenticação configurada na VPS
- [ ] Scripts executáveis (`chmod +x`)
- [ ] Secrets carregados (`./scripts/load_secrets_1p.sh`)
- [ ] Containers Docker rodando
- [ ] Banco de dados inicializado
- [ ] Dados importados

## 🔗 Referências

- [`INTEGRACAO_1PASSWORD.md`](INTEGRACAO_1PASSWORD.md) - Guia geral de integração
- [`SETUP_VPS_DOCKER.md`](SETUP_VPS_DOCKER.md) - Setup com Docker
- [1Password CLI Docs](https://developer.1password.com/docs/cli)

