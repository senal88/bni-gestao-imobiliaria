# 📚 Índice Completo de Templates - BNI Gestão Imobiliária

Guia rápido para navegar em todos os templates e recursos disponíveis.

## 🎯 Início Rápido

- **Novo no projeto?** → Comece por [`README_TEMPLATES.md`](README_TEMPLATES.md)
- **Quer criar o frontend?** → Execute [`setup-frontend.sh`](setup-frontend.sh)
- **Precisa entender os dados?** → Veja [`exemplos_reais_propriedades.json`](exemplos_reais_propriedades.json)

---

## 📂 Estrutura de Arquivos

### 📋 Documentação Principal

| Arquivo | Descrição | Quando Usar |
|---------|-----------|-------------|
| [`README_TEMPLATES.md`](README_TEMPLATES.md) | Visão geral de todos os templates | Primeira leitura |
| [`README_FRONTEND.md`](README_FRONTEND.md) | Documentação completa do frontend | Desenvolvimento frontend |
| [`INDEX_TEMPLATES.md`](INDEX_TEMPLATES.md) | Este arquivo - índice completo | Navegação rápida |

### 🎨 Frontend

| Arquivo | Descrição | Quando Usar |
|---------|-----------|-------------|
| [`frontend-project-context-bni.md`](frontend-project-context-bni.md) | Especificação completa do projeto frontend | Setup e desenvolvimento |
| [`setup-frontend.sh`](setup-frontend.sh) | Script automatizado de setup | Criação inicial do frontend |
| [`frontend-project-context.md`](frontend-project-context.md) | Template genérico (referência) | Entender estrutura genérica |
| [`generate-frontend-repo.sh`](generate-frontend-repo.sh) | Gerador genérico (referência) | Entender automação |

### 🗄️ Backend e Dados

| Arquivo | Descrição | Quando Usar |
|---------|-----------|-------------|
| [`imob_schema.sql`](imob_schema.sql) | Schema SQL de referência | Estrutura de banco de dados |
| [`etl.py`](etl.py) | Script ETL para processar PDFs | Processar relatórios PDF |
| [`imoveis_staging.jsonl`](imoveis_staging.jsonl) | Dados de staging JSON Lines | Dados processados |
| [`exemplos_reais_propriedades.json`](exemplos_reais_propriedades.json) | 10 propriedades reais | Exemplos e testes |

### 📖 Templates de Desenvolvimento

| Arquivo | Descrição | Quando Usar |
|---------|-----------|-------------|
| [`Exemplo_Para_Desenvolvimento_Template/Template_Em_Desenvolvimento_Parte_I.md`](Exemplo_Para_Desenvolvimento_Template/Template_Em_Desenvolvimento_Parte_I.md) | Modelo relacional SQL e JSON | Arquitetura de dados |
| [`Exemplo_Para_Desenvolvimento_Template/Template_Em_Desenvolvimento_Parte_2.md`](Exemplo_Para_Desenvolvimento_Template/Template_Em_Desenvolvimento_Parte_2.md) | Estrutura de dados e normalização | Normalização de dados |
| [`Exemplo_Para_Desenvolvimento_Template/Template_Em_Desenvolvimento_Parte_3.md`](Exemplo_Para_Desenvolvimento_Template/Template_Em_Desenvolvimento_Parte_3.md) | Blueprint FastAPI + Jinja2 | Desenvolvimento backend |

### 🛠️ Utilitários

| Arquivo | Descrição | Quando Usar |
|---------|-----------|-------------|
| [`parse_context.py`](parse_context.py) | Parser de contexto | Processamento de templates |
| [`run.sh`](run.sh) | Script de execução | Executar templates |
| [`prompt_diagnostico_frontend.md`](prompt_diagnostico_frontend.md) | Diagnóstico de capacidades | Referência técnica |

---

## 🗺️ Fluxos de Trabalho

### 🚀 Criar Novo Frontend

```bash
# 1. Execute o script de setup
cd templates
./setup-frontend.sh

# 2. Configure variáveis de ambiente
cd ../frontend
cp .env.example .env

# 3. Inicie desenvolvimento
make dev
```

**Documentação**: [`README_FRONTEND.md`](README_FRONTEND.md)

### 📊 Processar Dados do PDF

```bash
# 1. Coloque o PDF na pasta templates
# 2. Execute o ETL
python templates/etl.py

# 3. Dados processados em imoveis_staging.jsonl
```

**Referência**: [`etl.py`](etl.py)

### 🗄️ Entender Estrutura de Dados

1. Leia [`imob_schema.sql`](imob_schema.sql) para estrutura SQL
2. Veja [`exemplos_reais_propriedades.json`](exemplos_reais_propriedades.json) para exemplos
3. Consulte [`Template_Em_Desenvolvimento_Parte_I.md`](Exemplo_Para_Desenvolvimento_Template/Template_Em_Desenvolvimento_Parte_I.md) para modelo completo

---

## 📌 Dados Oficiais

### Fonte Única de Verdade

- **CSV**: `data/raw/propriedades.csv` (38 propriedades reais)
- **Código de Família**: `BNI_GESTAO_IMOBILIARIA`
- **Nome da Família**: `BNI Gestão Imobiliária`

### ⚠️ Regras Importantes

1. **SEMPRE** use dados reais do CSV
2. **NUNCA** use dados fictícios
3. **SEMPRE** referencie `data/raw/propriedades.csv` como fonte oficial
4. **VERIFIQUE** se exemplos estão atualizados

---

## 🔍 Busca Rápida

### Por Tipo de Recurso

- **Frontend**: `frontend-project-context-bni.md`, `setup-frontend.sh`, `README_FRONTEND.md`
- **Backend**: `Template_Em_Desenvolvimento_Parte_3.md`, `imob_schema.sql`
- **Dados**: `exemplos_reais_propriedades.json`, `imoveis_staging.jsonl`
- **ETL**: `etl.py`, `parse_context.py`

### Por Objetivo

- **Criar frontend**: `setup-frontend.sh` → `README_FRONTEND.md`
- **Entender dados**: `exemplos_reais_propriedades.json` → `imob_schema.sql`
- **Processar PDF**: `etl.py` → `imoveis_staging.jsonl`
- **Desenvolver backend**: `Template_Em_Desenvolvimento_Parte_3.md`

---

## 📝 Notas de Versão

- **Última atualização**: 2025-01-15
- **Versão dos templates**: 1.0.0
- **Compatibilidade**: macOS Silicon e Ubuntu VPS

---

## 🆘 Precisa de Ajuda?

1. **Dúvidas gerais**: [`README_TEMPLATES.md`](README_TEMPLATES.md)
2. **Frontend**: [`README_FRONTEND.md`](README_FRONTEND.md)
3. **Dados**: [`exemplos_reais_propriedades.json`](exemplos_reais_propriedades.json)
4. **Arquitetura**: [`Template_Em_Desenvolvimento_Parte_I.md`](Exemplo_Para_Desenvolvimento_Template/Template_Em_Desenvolvimento_Parte_I.md)

---

**Mantenha este índice atualizado ao adicionar novos templates!**

