# Documentação do Sistema BNI Gestão Imobiliária

## Visão Geral

O Sistema de Gestão Imobiliária BNI é uma solução completa para gerenciamento de portfólio de propriedades, desenvolvido em Python, integrando múltiplas ferramentas e plataformas para automatizar processos de gestão, relatórios e sincronização de dados.

## Arquitetura

### Componentes Principais

1. **Validador de CSV** (`src/validators/csv_validator.py`)
   - Valida dados de propriedades contra schema predefinido
   - Garante integridade e consistência dos dados
   - Suporta validações de tipo, formato, range e enumerações

2. **Sincronizador Hugging Face** (`src/sync/hf_sync.py`)
   - Sincroniza dados do portfólio com Hugging Face Datasets
   - Mantém backup em nuvem dos dados
   - Suporta sincronização bidirecional

3. **API REST** (`src/api/main.py`)
   - Construída com FastAPI
   - Endpoints para consulta e filtragem de propriedades
   - Estatísticas agregadas do portfólio
   - Documentação automática via Swagger/OpenAPI

4. **Gerador de Relatórios IFRS** (`src/reports/ifrs_reports.py`)
   - Gera relatórios financeiros compatíveis com IFRS
   - Suporta formatos PDF e Excel
   - Inclui: Balanço Patrimonial, Demonstração de Resultado, Schedule de Propriedades

5. **Gerador Obsidian** (`src/sync/obsidian_generator.py`)
   - Cria notas Markdown para Obsidian
   - Gera dashboard do portfólio
   - Links entre notas para navegação

6. **CI/CD Pipeline** (`.github/workflows/deploy.yml`)
   - Validação automática de dados
   - Deploy para VPS PostgreSQL
   - Sincronização com Hugging Face
   - Geração automática de relatórios

## Schema de Dados

### Estrutura CSV

```csv
id_propriedade,nome,tipo,endereco,cidade,estado,cep,area_m2,valor_aquisicao,data_aquisicao,valor_atual,renda_mensal,inquilino,status
```

### Validações

- **id_propriedade**: Padrão PROP\d{3} (ex: PROP001)
- **tipo**: Enum [Residencial, Comercial, Industrial, Terreno]
- **estado**: 2 caracteres
- **cep**: Formato 00000-000
- **area_m2**: Float > 0
- **valores**: Float >= 0
- **data_aquisicao**: Formato YYYY-MM-DD
- **status**: Enum [Ocupada, Vaga, Em Reforma, À Venda]

## API Endpoints

### GET /properties
Lista todas as propriedades com filtros opcionais:
- `tipo`: Tipo de propriedade
- `estado`: Estado (UF)
- `status`: Status da propriedade
- `min_valor`: Valor mínimo
- `max_valor`: Valor máximo

### GET /properties/{property_id}
Retorna detalhes de uma propriedade específica.

### GET /stats
Retorna estatísticas agregadas do portfólio:
- Total de propriedades
- Valor total
- Renda mensal e anual
- Distribuição por tipo e estado
- Contagem por status

### GET /health
Health check da API.

## Relatórios IFRS

### Balanço Patrimonial (IAS 1)
- Propriedades de Investimento (IAS 40)
- Propriedades de Uso Próprio (IAS 16)
- Terrenos (IAS 16)
- Valoração (custo vs valor justo)

### Demonstração de Resultado (IAS 1)
- Receitas de aluguel
- Rendimento anual projetado
- Taxa de retorno (yield)
- Distribuição por tipo

### Schedule de Propriedades (IFRS 13)
- Detalhamento completo de cada propriedade
- Métricas de valorização
- Yield individual

## Integração Obsidian

### Templates

1. **Property Template** - Nota individual de propriedade
   - Informações básicas e localização
   - Características e métricas financeiras
   - Histórico e documentação
   - Checklist de manutenção

2. **Portfolio Dashboard** - Visão geral do portfólio
   - Estatísticas principais
   - Distribuição por tipo e localização
   - Top 5 propriedades
   - Ações necessárias

### Uso no Obsidian

1. Copie os arquivos gerados para seu vault do Obsidian
2. Use a busca por tags: `#propriedade #bni`
3. Navegue pelo dashboard para visão geral
4. Links entre notas facilitam navegação

## GitHub Actions Workflow

### Jobs

1. **validate**: Valida CSV e executa testes
2. **sync-huggingface**: Sincroniza com Hugging Face Dataset
3. **deploy-database**: Deploy para PostgreSQL no VPS
4. **generate-reports**: Gera relatórios IFRS
5. **generate-obsidian**: Cria notas Obsidian

### Secrets Necessários

```
HF_TOKEN: Token do Hugging Face
HF_DATASET_NAME: Nome do dataset (username/dataset-name)
VPS_HOST: IP/domínio do VPS
VPS_USER: Usuário SSH
VPS_SSH_KEY: Chave SSH privada
DB_HOST: Host do PostgreSQL
DB_PORT: Porta do PostgreSQL (5432)
DB_NAME: Nome do banco de dados
DB_USER: Usuário do banco
DB_PASSWORD: Senha do banco
```

## Desenvolvimento

### Setup Local

```bash
# Criar ambiente virtual
python -m venv venv
source venv/bin/activate

# Instalar dependências
pip install -r requirements.txt

# Instalar em modo desenvolvimento
pip install -e .
```

### Executar Testes

```bash
# Todos os testes
pytest tests/ -v

# Com cobertura
pytest tests/ --cov=src --cov-report=html
```

### Executar API Localmente

```bash
# Via main.py
python main.py api --reload

# Diretamente
python src/api/main.py
```

## Manutenção

### Atualizar Dados

1. Editar `data/raw/properties.csv`
2. Validar: `python main.py validate data/raw/properties.csv`
3. Commit e push (GitHub Actions fará o resto)

### Adicionar Nova Propriedade

1. Adicionar linha no CSV seguindo o schema
2. Executar validação
3. Gerar novos relatórios e notas

### Backup

- Dados sincronizados automaticamente com Hugging Face
- PostgreSQL no VPS mantém dados persistentes
- Relatórios gerados como artifacts no GitHub

## Monitoramento

### Logs

- API: Logs em stdout/stderr
- GitHub Actions: Logs disponíveis na aba Actions
- PostgreSQL: Logs do servidor

### Métricas

- Total de propriedades
- Valor total do portfólio
- Renda mensal total
- Taxa de ocupação
- Distribuição geográfica

## Troubleshooting

### Erro de Validação CSV

- Verificar formato de campos obrigatórios
- Conferir enums (tipo, status)
- Validar formato de data (YYYY-MM-DD)
- Verificar CEP (00000-000)

### Erro na API

- Verificar se arquivo CSV existe
- Conferir formato dos dados
- Verificar logs da aplicação

### Falha no Deploy

- Verificar secrets do GitHub
- Confirmar acesso SSH ao VPS
- Validar credenciais PostgreSQL
- Revisar logs do workflow

## Segurança

### Best Practices

1. **Secrets**: Nunca commitar tokens ou senhas
2. **SSH**: Usar chaves SSH, não senhas
3. **PostgreSQL**: Configurar firewall, usar SSL/TLS
4. **Hugging Face**: Manter dataset privado
5. **API**: Implementar autenticação em produção

### Conformidade

- **IFRS**: Relatórios seguem padrões internacionais
- **LGPD**: Dados sensíveis devem ser protegidos
- **Backup**: Múltiplas cópias dos dados

## Roadmap

### Curto Prazo
- [ ] Dashboard web interativo
- [ ] Sistema de notificações
- [ ] Integração com APIs de avaliação

### Médio Prazo
- [ ] Mobile app
- [ ] Análise preditiva
- [ ] Integração contábil

### Longo Prazo
- [ ] Machine Learning para precificação
- [ ] Automação de processos legais
- [ ] Marketplace integrado

## Suporte

Para dúvidas ou problemas:
1. Consultar esta documentação
2. Verificar logs do sistema
3. Abrir issue no GitHub
4. Contatar equipe BNI

---

**Última Atualização**: 2025-11-15
**Versão**: 1.0.0
