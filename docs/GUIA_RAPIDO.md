# ⚡ Guia Rápido - Onde Executar Cada Comando

Este guia deixa claro **onde** (Mac ou VPS) executar cada comando.

## 🍎 macOS Silicon (Desenvolvimento Local)

### O que roda no Mac:
- ✅ Desenvolvimento de código
- ✅ Testes locais
- ✅ Docker Desktop (PostgreSQL local)
- ✅ Scripts Python locais
- ✅ Validação de schemas
- ✅ Geração de relatórios locais

### Comandos para executar no Mac:

```bash
# No seu Mac
cd ~/bni-gestao-imobiliaria

# Instalar dependências
make install

# Iniciar PostgreSQL local (Docker Desktop)
make docker-up

# Inicializar banco local
make init-db

# Importar dados localmente
make import-properties

# Validar schemas
make validate-schemas

# Gerar relatórios
make generate-reports
```

## 🖥️ VPS (Produção)

### O que roda na VPS:
- ✅ PostgreSQL de produção
- ✅ Sincronização automática com Hugging Face
- ✅ Deploy automático via GitHub Actions
- ✅ Backup de dados
- ✅ Sincronização agendada (cron)

### Comandos para executar na VPS:

```bash
# Conectar na VPS (do Mac)
ssh vps

# Agora você está DENTRO da VPS
cd /opt/bni-gestao-imobiliaria

# Executar script de setup completo
./scripts/setup_vps_completo.sh

# Ou seguir manualmente:
source venv/bin/activate
python scripts/init_database.py
python scripts/import_propriedades.py
```

## 📋 Fluxo de Trabalho Recomendado

### 1. Desenvolvimento no Mac

```bash
# No Mac: desenvolver e testar localmente
cd ~/bni-gestao-imobiliaria
make docker-up
make init-db
make import-properties
make validate-schemas
```

### 2. Commit e Push

```bash
# No Mac: commitar mudanças
git add .
git commit -m "Descrição das mudanças"
git push origin main
```

### 3. Deploy Automático na VPS

- GitHub Actions detecta o push
- Executa deploy automático na VPS
- Atualiza código, instala dependências
- Roda migrations se necessário

### 4. Verificação na VPS

```bash
# Conectar na VPS para verificar
ssh vps
cd /opt/bni-gestao-imobiliaria
docker ps  # Ver containers rodando
```

## 🔄 Sincronização de Dados

### Mac → Hugging Face (manual)

```bash
# No Mac: sincronizar dados locais
make sync-hf
```

### VPS → Hugging Face (automático)

- Executado automaticamente via GitHub Actions
- Ou manualmente na VPS:
```bash
ssh vps
cd /opt/bni-gestao-imobiliaria
source venv/bin/activate
python scripts/sync_huggingface.py --push
```

## 📊 Resumo Visual

```
┌─────────────────┐
│   macOS Silicon │
│   (Desenvolvimento) │
├─────────────────┤
│ • Docker Desktop│
│ • PostgreSQL    │
│   (localhost)   │
│ • Scripts Python│
│ • Testes        │
└────────┬────────┘
         │
         │ git push
         │
         ▼
┌─────────────────┐
│   GitHub        │
│   (Repositório) │
└────────┬────────┘
         │
         │ GitHub Actions
         │
         ▼
┌─────────────────┐
│   VPS OVH       │
│   (Produção)    │
├─────────────────┤
│ • PostgreSQL    │
│   (Produção)    │
│ • Deploy Auto   │
│ • Cron Jobs     │
└────────┬────────┘
         │
         │ sync
         │
         ▼
┌─────────────────┐
│  Hugging Face   │
│  (Dataset)       │
└─────────────────┘
```

## ⚠️ Importante

- **Mac**: Use para desenvolvimento, testes e commits
- **VPS**: Use para produção, deploy e sincronização automática
- **Nunca** desenvolva diretamente na VPS (use Mac + Git)
- **Sempre** teste no Mac antes de fazer push

## 🔗 Documentação Detalhada

- Setup Mac: [`SETUP_MACOS.md`](SETUP_MACOS.md)
- Setup VPS: [`SETUP_VPS.md`](SETUP_VPS.md)
- Deploy: [`CONFIGURACAO_DEPLOY.md`](CONFIGURACAO_DEPLOY.md)

