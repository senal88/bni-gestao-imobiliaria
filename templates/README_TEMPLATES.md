# 📋 Templates - BNI Gestão Imobiliária

Esta pasta contém templates e exemplos para desenvolvimento. **Todos os exemplos foram atualizados para usar dados reais do banco de dados.**

## ⚠️ IMPORTANTE

**Todos os dados de exemplo foram substituídos por dados reais do arquivo:**
- `data/raw/propriedades.csv`

**Não há mais dados fictícios como:**
- ❌ "FAMILIA_SILVA" → ✅ "BNI_GESTAO_IMOBILIARIA"
- ❌ "Ed. Mariner" → ✅ "APTO 802 EDF.EMILIO BUMACHAR"
- ❌ "Balneário Camboriú" → ✅ "Vila Velha" (e outras cidades reais)

## 📁 Estrutura de Arquivos

### Schemas e Modelos

- **`imob_schema.sql`** - Schema PostgreSQL completo para gestão imobiliária
  - Usa dados reais do CSV
  - Exemplos atualizados com propriedades reais

- **`etl.py`** - Script ETL para processar relatórios PDF
  - Gera JSON normalizado baseado em dados reais
  - Usa código de família: `BNI_GESTAO_IMOBILIARIA`

### Dados de Exemplo

- **`imoveis_staging.jsonl`** - Dados de staging em formato JSON Lines
  - **ATENÇÃO:** Este arquivo contém dados processados do PDF original
  - Para dados oficiais, use: `data/raw/propriedades.csv`

- **`exemplos_reais_propriedades.json`** - Exemplos extraídos do CSV real
  - Gerado automaticamente do arquivo oficial
  - Contém propriedades reais para uso em templates

### Templates de Desenvolvimento

- **`Exemplo_Para_Desenvolvimento_Template/`** - Templates para desenvolvimento
  - Todos os exemplos atualizados com dados reais
  - Schema SQL com comentários usando propriedades reais

### Frontend

- **`prompt_diagnostico_frontend.md`** - Prompt para diagnóstico de frontend
- **`frontend-project-context.md`** - Contexto de projeto frontend
- **`generate-frontend-repo.sh`** - Script para gerar repositório frontend

## 🔄 Dados Oficiais

**Fonte única de verdade:**
```
data/raw/propriedades.csv
```

**Total de propriedades:** 38 imóveis reais

**Tipos de estoque:**
- Concluídos
- De Terceiros
- N/D

**Status possíveis:**
- Concluído
- Locado
- Promessa_Compra_Venda
- Vendido/Reclassificado
- Aporte SCP

## 📊 Exemplos Reais

### Propriedade 1
- **Código:** 51001
- **Nome:** APTO 802 EDF.EMILIO BUMACHAR
- **Tipo:** Concluídos
- **Valor 2024:** R$ 44.886,16
- **Status:** Concluído

### Propriedade 2
- **Código:** 51002
- **Nome:** APTO 902 EDF.EMILIO BUMACHAR
- **Tipo:** Concluídos
- **Valor 2024:** R$ 56.226,27
- **Status:** Concluído

### Propriedade 3
- **Código:** 51025
- **Nome:** ED. YOUNIVERSE APTO 1310
- **Tipo:** De Terceiros
- **Valor 2023:** R$ 653.720,00
- **Status:** Vendido/Reclassificado

## 🚀 Como Usar

### Para Desenvolvimento

1. Use os exemplos em `exemplos_reais_propriedades.json`
2. Consulte `data/raw/propriedades.csv` para dados completos
3. Use `imob_schema.sql` como referência do schema

### Para ETL

1. Execute `etl.py` para processar PDFs
2. O output será em formato JSON normalizado
3. Use dados reais do CSV para validação

### Para Frontend

1. Use `generate-frontend-repo.sh` para criar estrutura
2. Consulte `frontend-project-context.md` para configuração
3. Use dados reais do CSV para mockups e testes

## ⚠️ Avisos

- **NÃO** use dados fictícios em produção
- **SEMPRE** referencie `data/raw/propriedades.csv` como fonte oficial
- **VERIFIQUE** se exemplos estão atualizados antes de usar
- **ATUALIZE** templates quando novos dados forem adicionados

## 📝 Manutenção

Para atualizar exemplos quando novos dados forem adicionados:

```bash
# Gerar novos exemplos do CSV
python3 << 'EOF'
import csv
import json

with open('data/raw/propriedades.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    propriedades = list(reader)

# Processar e salvar exemplos
# ... (ver script completo em templates/)
EOF
```

## 🔗 Referências

- Schema oficial: `scripts/init.sql`
- Dados oficiais: `data/raw/propriedades.csv`
- Script de importação: `scripts/import_propriedades.py`

