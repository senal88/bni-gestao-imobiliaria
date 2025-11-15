.PHONY: help init-db sync-hf validate-schemas generate-reports export-obsidian test lint format clean install docker-up docker-down type-check load-secrets-1p setup all import-properties

# Cores para output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m # No Color

help: ## Mostra esta mensagem de ajuda
	@echo "$(BLUE)BNI Gestão Imobiliária - Comandos Disponíveis$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

install: ## Instala as dependências do projeto
	@echo "$(BLUE)Instalando dependências...$(NC)"
	pip install -r requirements.txt
	@echo "$(GREEN)✓ Dependências instaladas$(NC)"

init-db: ## Inicializa o banco de dados PostgreSQL
	@echo "$(BLUE)Inicializando banco de dados...$(NC)"
	python scripts/init_database.py
	@echo "$(GREEN)✓ Banco de dados inicializado$(NC)"

sync-hf: ## Sincroniza dados com Hugging Face Dataset
	@echo "$(BLUE)Sincronizando com Hugging Face...$(NC)"
	python scripts/sync_huggingface.py
	@echo "$(GREEN)✓ Sincronização concluída$(NC)"

validate-schemas: ## Valida schemas CSV dos dados
	@echo "$(BLUE)Validando schemas...$(NC)"
	python scripts/validate_schemas.py
	@echo "$(GREEN)✓ Validação concluída$(NC)"

generate-reports: ## Gera relatórios IFRS
	@echo "$(BLUE)Gerando relatórios IFRS...$(NC)"
	python scripts/generate_ifrs_reports.py
	@echo "$(GREEN)✓ Relatórios gerados$(NC)"

export-obsidian: ## Exporta dados para templates Obsidian
	@echo "$(BLUE)Exportando para Obsidian...$(NC)"
	python scripts/export_to_obsidian.py
	@echo "$(GREEN)✓ Exportação concluída$(NC)"

import-properties: ## Importa propriedades do CSV para PostgreSQL
	@echo "$(BLUE)Importando propriedades...$(NC)"
	python scripts/import_propriedades.py
	@echo "$(GREEN)✓ Importação concluída$(NC)"

test: ## Executa testes automatizados
	@echo "$(BLUE)Executando testes...$(NC)"
	pytest tests/ -v --cov=. --cov-report=html
	@echo "$(GREEN)✓ Testes concluídos$(NC)"

lint: ## Executa linting no código
	@echo "$(BLUE)Executando linting...$(NC)"
	ruff check .
	flake8 scripts/ tests/ --max-line-length=100 --exclude=venv,__pycache__
	@echo "$(GREEN)✓ Linting concluído$(NC)"

format: ## Formata o código com black
	@echo "$(BLUE)Formatando código...$(NC)"
	black scripts/ tests/ --line-length=100
	@echo "$(GREEN)✓ Código formatado$(NC)"

type-check: ## Verifica tipos com mypy
	@echo "$(BLUE)Verificando tipos...$(NC)"
	mypy scripts/ --ignore-missing-imports
	@echo "$(GREEN)✓ Verificação de tipos concluída$(NC)"

docker-up: ## Inicia containers Docker
	@echo "$(BLUE)Iniciando containers Docker...$(NC)"
	docker-compose up -d
	@echo "$(GREEN)✓ Containers iniciados$(NC)"

docker-down: ## Para containers Docker
	@echo "$(BLUE)Parando containers Docker...$(NC)"
	docker-compose down
	@echo "$(GREEN)✓ Containers parados$(NC)"

clean: ## Limpa arquivos temporários e caches
	@echo "$(BLUE)Limpando arquivos temporários...$(NC)"
	find . -type d -name "__pycache__" -exec rm -r {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type d -name "*.egg-info" -exec rm -r {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -r {} + 2>/dev/null || true
	find . -type d -name ".ruff_cache" -exec rm -r {} + 2>/dev/null || true
	rm -rf htmlcov/ .coverage
	@echo "$(GREEN)✓ Limpeza concluída$(NC)"

load-secrets-1p: ## Carrega secrets do 1Password para .env
	@echo "$(BLUE)Carregando secrets do 1Password...$(NC)"
	@./scripts/load_secrets_1p.sh
	@echo "$(GREEN)✓ Secrets carregados!$(NC)"

setup: install load-secrets-1p init-db ## Setup completo: instala dependências, carrega secrets e inicializa banco
	@echo "$(GREEN)✓ Setup completo!$(NC)"

all: validate-schemas sync-hf generate-reports ## Executa pipeline completo: valida, sincroniza e gera relatórios
	@echo "$(GREEN)✓ Pipeline completo executado!$(NC)"

