# 🍎 Setup no macOS Silicon

Este guia é específico para **configuração local no seu Mac**.

## 📋 Pré-requisitos macOS

- macOS com Apple Silicon (M1/M2/M3)
- Homebrew instalado
- Git instalado
- Terminal (zsh)

## 🚀 Passo 1: Instalar Dependências no Mac

```bash
# Instalar Python via Homebrew
brew install python@3.11

# Instalar Docker Desktop (se ainda não tiver)
brew install --cask docker

# Iniciar Docker Desktop
open -a Docker
```

## 📦 Passo 2: Clonar e Configurar Projeto no Mac

```bash
# Navegar para diretório de projetos
cd ~/code  # ou onde você mantém seus projetos

# Clonar repositório (se ainda não clonou)
git clone https://github.com/senal88/bni-gestao-imobiliaria.git
cd bni-gestao-imobiliaria

# Criar ambiente virtual Python
python3 -m venv venv
source venv/bin/activate

# Instalar dependências Python
pip install -r requirements.txt
```

## ⚙️ Passo 3: Configurar Variáveis de Ambiente no Mac

```bash
# Copiar arquivo de exemplo
cp .env.example .env

# Editar .env com suas configurações locais
nano .env  # ou use seu editor preferido
```

**Configuração para desenvolvimento local no Mac:**

```bash
# PostgreSQL (via Docker Compose)
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=bni_gestao
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres

# Hugging Face (seu token)
HF_TOKEN=seu_token_aqui
HF_DATASET_NAME=senal88/bni-gestao-imobiliaria

# Paths locais
DATA_RAW_PATH=./data/raw
DATA_PROCESSED_PATH=./data/processed
DATA_SCHEMAS_PATH=./data/schemas
```

## 🐳 Passo 4: Iniciar PostgreSQL com Docker no Mac

```bash
# Iniciar containers Docker (PostgreSQL + pgAdmin)
docker-compose up -d

# Verificar se está rodando
docker ps

# Ver logs do PostgreSQL
docker logs bni_postgres
```

## 🗄️ Passo 5: Inicializar Banco de Dados no Mac

```bash
# Com ambiente virtual ativado
source venv/bin/activate

# Inicializar banco de dados
make init-db

# Ou diretamente
python scripts/init_database.py
```

## 📊 Passo 6: Importar Dados no Mac

```bash
# Validar schemas primeiro
make validate-schemas

# Importar propriedades (dry-run primeiro)
python scripts/import_propriedades.py --dry-run

# Importar propriedades (real)
make import-properties
```

## ✅ Verificar Setup no Mac

```bash
# Testar conexão com banco
python scripts/init_database.py --validate-only

# Ver dados importados
docker exec -it bni_postgres psql -U postgres -d bni_gestao -c "SELECT COUNT(*) FROM propriedades;"
```

## 🔧 Comandos Úteis no Mac

```bash
# Parar Docker
docker-compose down

# Ver logs
docker-compose logs -f

# Acessar pgAdmin (interface web)
open http://localhost:5050
# Login: admin@bni.local / admin
```

## 📝 Notas Importantes para Mac

- ✅ Todo desenvolvimento local acontece no **Mac**
- ✅ PostgreSQL roda via **Docker Desktop** no Mac
- ✅ Scripts Python executam no **Mac** (não na VPS)
- ✅ VPS é usado apenas para **produção/deploy**

## 🔗 Próximos Passos

Após configurar o Mac, configure a VPS:
- [`SETUP_VPS.md`](SETUP_VPS.md) - Setup completo na VPS

