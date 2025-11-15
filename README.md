# 🏢 BNI Gestão Imobiliária

Sistema completo de gestão do portfólio imobiliário BNI: 38 propriedades integradas com Hugging Face, Obsidian, PostgreSQL e relatórios IFRS automatizados.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.9+](https://img.shields.io/badge/python-3.9+-blue.svg)](https://www.python.org/downloads/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-blue.svg)](https://www.postgresql.org/)

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Funcionalidades](#funcionalidades)
- [Arquitetura](#arquitetura)
- [Instalação](#instalação)
- [Configuração](#configuração)
- [Uso](#uso)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Documentação](#documentação)
- [Contribuindo](#contribuindo)
- [Licença](#licença)

## 🎯 Visão Geral

Sistema de gestão imobiliária desenvolvido para administrar um portfólio de 38 propriedades da BNI. O sistema integra múltiplas tecnologias para fornecer uma solução completa de gestão, desde a sincronização de dados até a geração de relatórios financeiros.

### Principais Integrações

- **Hugging Face**: Dataset público para compartilhamento e versionamento de dados
- **Obsidian**: Templates Markdown para documentação e notas
- **PostgreSQL**: Banco de dados relacional para armazenamento estruturado
- **GitHub Actions**: CI/CD para deploy automático
- **IFRS**: Geração automatizada de relatórios financeiros

## ✨ Funcionalidades

### 📊 Gestão de Propriedades

- Cadastro completo de 38 propriedades
- Validação automatizada de schema CSV
- Sincronização bidirecional com Hugging Face Dataset
- Histórico de alterações e versionamento

### 🔄 Sincronização e Integração

- Scripts Python para sincronização automática
- Workflows GitHub Actions para deploy em VPS PostgreSQL
- API REST para consumo de dados
- Exportação para múltiplos formatos (CSV, JSON, Markdown)

### 📈 Relatórios e Análises

- Geração de relatórios financeiros IFRS
- Dashboards e visualizações
- Exportação de dados para análise

### 📝 Documentação

- Templates Obsidian para notas estruturadas
- ADRs (Architecture Decision Records)
- Documentação técnica completa

## 🏗️ Arquitetura

```
┌─────────────────┐
│  Hugging Face   │
│     Dataset     │
└────────┬────────┘
         │
         │ Sync Scripts
         │
┌────────▼────────┐     ┌──────────────┐
│   PostgreSQL    │◄────│  GitHub      │
│      (VPS)      │     │  Actions     │
└────────┬────────┘     └──────────────┘
         │
         │ API REST
         │
┌────────▼────────┐
│   Obsidian      │
│    Templates    │
└─────────────────┘
```

## 🚀 Instalação Rápida

### 🍎 No macOS Silicon (Desenvolvimento Local)

```bash
# 1. Clone o repositório
git clone https://github.com/senal88/bni-gestao-imobiliaria.git
cd bni-gestao-imobiliaria

# 2. Instale dependências
make install

# 3. Configure variáveis de ambiente
cp .env.example .env
# Edite .env com suas configurações

# 4. Inicie PostgreSQL (Docker Desktop)
make docker-up

# 5. Inicialize banco de dados
make init-db

# 6. Importe dados
make import-properties
```

📖 **Guia completo**: [`docs/SETUP_MACOS.md`](docs/SETUP_MACOS.md)

### 🖥️ Na VPS (Produção)

```bash
# 1. Conecte na VPS
ssh vps

# 2. Execute script de setup completo
cd /opt/bni-gestao-imobiliaria
./scripts/setup_vps_completo.sh

# 3. Configure variáveis de ambiente
nano .env  # Configure HF_TOKEN e outras variáveis

# 4. Importe dados
source venv/bin/activate
python scripts/import_propriedades.py
```

📖 **Guia completo**: [`docs/SETUP_VPS.md`](docs/SETUP_VPS.md)

### ⚡ Guia Rápido: Mac vs VPS

📖 **Consulte**: [`docs/GUIA_RAPIDO.md`](docs/GUIA_RAPIDO.md) para saber **onde** executar cada comando

## ⚙️ Configuração

### Variáveis de Ambiente

Copie o arquivo `.env.example` para `.env` e configure as seguintes variáveis:

```bash
# Database
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=bni_gestao
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_password

# Hugging Face
HF_TOKEN=your_huggingface_token
HF_DATASET_NAME=senal88/bni-gestao-imobiliaria

# API
API_HOST=0.0.0.0
API_PORT=8000

# Obsidian
OBSIDIAN_VAULT_PATH=./obsidian/vault_backup
```

### Configuração do PostgreSQL

O sistema suporta deploy automático em VPS PostgreSQL através de GitHub Actions. Configure os secrets no GitHub:

- `POSTGRES_HOST`
- `POSTGRES_PORT`
- `POSTGRES_DB`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `SSH_PRIVATE_KEY`
- `SSH_HOST`

## 📖 Uso

### Comandos Make (Recomendado)

```bash
# Inicializar banco de dados
make init-db

# Sincronizar com Hugging Face
make sync-hf

# Validar schemas CSV
make validate-schemas

# Gerar relatórios IFRS
make generate-reports

# Executar testes
make test

# Executar linting
make lint

# Formatar código
make format
```

### Scripts Python Diretos

```bash
# Sincronizar com Hugging Face
python scripts/sync_huggingface.py

# Validar dados
python scripts/validate_schemas.py

# Gerar relatórios
python scripts/generate_ifrs_reports.py

# Exportar para Obsidian
python scripts/export_to_obsidian.py

# Inicializar banco de dados
python scripts/init_database.py
```

### Docker Compose

Para desenvolvimento local com PostgreSQL:

```bash
docker-compose up -d
```

## 📁 Estrutura do Projeto

```
bni-gestao-imobiliaria/
├── .github/
│   └── workflows/
│       ├── deploy-postgres.yml      # Deploy automático PostgreSQL
│       ├── sync-huggingface.yml     # Sincronização Hugging Face
│       └── validate-schemas.yml     # Validação de schemas
├── data/
│   ├── raw/                         # Dados brutos
│   ├── processed/                   # Dados processados
│   └── schemas/                     # Schemas de validação
├── docs/
│   └── ADR/                         # Architecture Decision Records
├── obsidian/
│   └── vault_backup/                # Backup do vault Obsidian
├── scripts/
│   ├── init_database.py            # Inicialização do banco
│   ├── sync_huggingface.py         # Sincronização HF
│   ├── validate_schemas.py          # Validação de schemas
│   ├── generate_ifrs_reports.py     # Relatórios IFRS
│   └── export_to_obsidian.py        # Exportação Obsidian
├── tests/                           # Testes automatizados
├── .env.example                     # Exemplo de variáveis de ambiente
├── .gitignore                       # Arquivos ignorados pelo Git
├── docker-compose.yml               # Configuração Docker
├── Makefile                         # Comandos simplificados
├── requirements.txt                 # Dependências Python
└── README.md                        # Este arquivo
```

## 📚 Documentação

### ⚡ Guia Rápido (Comece Aqui!)

- [`GUIA_RAPIDO.md`](docs/GUIA_RAPIDO.md) - **Onde executar cada comando** (Mac vs VPS)
  - 🍎 Comandos para macOS Silicon
  - 🖥️ Comandos para VPS
  - Fluxo de trabalho recomendado

### 🍎 Setup Local (macOS Silicon)

- [`SETUP_MACOS.md`](docs/SETUP_MACOS.md) - **Setup completo no seu Mac** (desenvolvimento local)
  - Instalação de dependências no Mac
  - Configuração Docker Desktop
  - Desenvolvimento e testes locais

### 🖥️ Setup Produção (VPS)

- [`SETUP_VPS_DOCKER.md`](docs/SETUP_VPS_DOCKER.md) - **🐳 Setup com Docker Compose** (recomendado)
  - Setup completo usando Docker na VPS
  - PostgreSQL em container isolado
  - Script automatizado: `scripts/setup_vps_docker.sh`

- [`SETUP_VPS.md`](docs/SETUP_VPS.md) - **Setup completo na VPS** (método alternativo)
  - Instalação completa na VPS OVH
  - Configuração Docker na VPS
  - Deploy e sincronização automática
  - Script automatizado: `scripts/setup_vps_completo.sh`

### Architecture Decision Records (ADRs)

Documentos de decisões arquiteturais importantes estão em `docs/ADR/`:

- `001-escolha-postgresql.md` - Decisão sobre banco de dados
- `002-integracao-huggingface.md` - Estratégia de integração HF
- `003-workflow-github-actions.md` - Automação de deploy

### Configuração e Deploy

- [`SETUP_1PASSWORD_VPS.md`](docs/SETUP_1PASSWORD_VPS.md) - 🔐 **Setup Completo com 1Password na VPS** (recomendado)
  - Instalação e autenticação automática
  - Scripts completos de setup
  - Gerenciamento de secrets sem senhas manuais

- [`INTEGRACAO_1PASSWORD.md`](docs/INTEGRACAO_1PASSWORD.md) - 🔐 **Integração com 1Password** (guia geral)
  - Configuração no Mac e VPS
  - Scripts automatizados
  - Integração com GitHub Actions

- [`CONFIGURACAO_PERSONALIZADA.md`](docs/CONFIGURACAO_PERSONALIZADA.md) - ⚡ **Configuração específica do seu ambiente** (recomendado começar aqui)
- [`CONFIGURACAO_DEPLOY.md`](docs/CONFIGURACAO_DEPLOY.md) - Guia completo de configuração do deploy no VPS
- [`RESUMO_CONFIGURACAO.md`](docs/RESUMO_CONFIGURACAO.md) - Checklist rápido de configuração

### Schemas de Dados

Os schemas de validação estão em `data/schemas/` e são utilizados para garantir a integridade dos dados antes da sincronização.

## 🧪 Testes

Execute os testes com:

```bash
make test
# ou
pytest tests/
```

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 👤 Autor

**senal88**

- GitHub: [@senal88](https://github.com/senal88)

## 🙏 Agradecimentos

- BNI por fornecer os dados do portfólio
- Comunidade Hugging Face pelo suporte a datasets
- Comunidade open source pelas ferramentas utilizadas

---

**⭐ Se este projeto foi útil para você, considere dar uma estrela no repositório!**
