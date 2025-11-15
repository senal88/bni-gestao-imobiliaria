# ⚡ Resumo Rápido - Configuração de Deploy

## 🎯 Checklist de Configuração

### 1. VPS Preparado ✅
- [x] Acesso SSH funcionando (`ssh vps`)
- [x] Containers PostgreSQL disponíveis
- [ ] Diretório `/opt/bni-gestao-imobiliaria` criado
- [ ] Repositório clonado no VPS

### 2. SSH Key Configurada ✅
- [x] Chave SSH existente: `~/.ssh/id_ed25519_universal` (já configurada)
- [x] Acesso SSH ao VPS funcionando (`ssh vps`)
- [ ] Verificar se chave pública está no VPS (opcional, para GitHub Actions)

### 3. Secrets do GitHub Configurados
Acesse: `https://github.com/senal88/bni-gestao-imobiliaria/settings/secrets/actions`

#### SSH (4 secrets)
- [ ] `SSH_PRIVATE_KEY` - Conteúdo de `~/.ssh/bni_deploy_key`
- [ ] `SSH_HOST` - Hostname do VPS (ex: `senamfo`)
- [ ] `SSH_USER` - Usuário (ex: `root`)
- [ ] `SSH_PORT` - Porta (padrão: `22`)

#### PostgreSQL (5 secrets)
- [ ] `POSTGRES_HOST` - Host do PostgreSQL
- [ ] `POSTGRES_PORT` - Porta (geralmente `5432`)
- [ ] `POSTGRES_DB` - Nome do banco (`bni_gestao`)
- [ ] `POSTGRES_USER` - Usuário (`postgres`)
- [ ] `POSTGRES_PASSWORD` - Senha do PostgreSQL

#### Hugging Face (2 secrets - opcional)
- [ ] `HF_TOKEN` - Token do Hugging Face
- [ ] `HF_DATASET_NAME` - Nome do dataset

## 🚀 Comandos Rápidos

### No seu Mac

```bash
# 1. Verificar se chave pública está no VPS (já deve estar)
ssh vps "cat ~/.ssh/authorized_keys | grep $(ssh-keygen -lf ~/.ssh/id_ed25519_universal.pub | awk '{print $2}')"

# 2. Se não estiver, adicionar:
cat ~/.ssh/id_ed25519_universal.pub | ssh vps "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# 3. Testar conexão (já deve funcionar)
ssh vps "echo 'OK'"

# 4. Ver conteúdo da chave privada (para GitHub Secret)
cat ~/.ssh/id_ed25519_universal

# OU criar chave dedicada para GitHub Actions:
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/bni_deploy_key
cat ~/.ssh/bni_deploy_key.pub | ssh vps "cat >> ~/.ssh/authorized_keys"
cat ~/.ssh/bni_deploy_key  # Para GitHub Secret
```

### No VPS

```bash
# 1. Identificar containers PostgreSQL
docker ps | grep postgres

# 2. Executar script de identificação
cd /opt/bni-gestao-imobiliaria
./scripts/identificar_postgres.sh

# 3. Criar banco de dados (se necessário)
docker exec -it <container_postgres> psql -U postgres -c "CREATE DATABASE bni_gestao;"

# 4. Clonar repositório (se ainda não clonou)
git clone https://github.com/senal88/bni-gestao-imobiliaria.git /opt/bni-gestao-imobiliaria
```

## 📋 Valores de Exemplo

Baseado no seu VPS atual:

```yaml
# SSH
SSH_HOST: 147.79.81.59  # IP do VPS (ou hostname se DNS configurado)
SSH_USER: root
SSH_PORT: 22

# PostgreSQL (exemplo - ajuste conforme seu container)
POSTGRES_HOST: localhost
POSTGRES_PORT: 5432
POSTGRES_DB: bni_gestao
POSTGRES_USER: postgres
POSTGRES_PASSWORD: <sua_senha>

# Hugging Face
HF_DATASET_NAME: senal88/bni-gestao-imobiliaria
```

## 🔍 Verificar Configuração

### Testar SSH
```bash
# Com sua configuração atual (já funciona)
ssh vps "cd /opt/bni-gestao-imobiliaria && pwd"

# Ou com IP direto (para GitHub Actions)
ssh -i ~/.ssh/id_ed25519_universal root@147.79.81.59 "cd /opt/bni-gestao-imobiliaria && pwd"
```

### Testar PostgreSQL
```bash
# No VPS
docker exec -it <container_postgres> psql -U postgres -d bni_gestao -c "SELECT 1;"
```

### Testar Deploy Manual
```bash
ssh -i ~/.ssh/bni_deploy_key root@senamfo << 'EOF'
cd /opt/bni-gestao-imobiliaria
export POSTGRES_HOST=localhost
export POSTGRES_PORT=5432
export POSTGRES_DB=bni_gestao
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=sua_senha
python3 scripts/init_database.py
EOF
```

## 📚 Documentação Completa

Para instruções detalhadas, consulte: [`docs/CONFIGURACAO_DEPLOY.md`](CONFIGURACAO_DEPLOY.md)

