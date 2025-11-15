# BNI Gestão Imobiliária

Sistema completo de gestão do portfólio imobiliário BNI com 38 propriedades, integrando Hugging Face Datasets, Obsidian, PostgreSQL e relatórios IFRS automatizados.

## 🎯 Funcionalidades

- ✅ **Validação automatizada de schema CSV** - Valida dados de propriedades contra schema definido
- ✅ **Sincronização com Hugging Face Dataset** - Mantém backup em nuvem dos dados do portfólio
- ✅ **API REST FastAPI** - Interface para consumo de dados do portfólio
- ✅ **Relatórios IFRS** - Geração automática de relatórios financeiros compatíveis com IFRS (IAS 1, 16, 40)
- ✅ **Integração com Obsidian** - Templates Markdown para gestão visual do portfólio
- ✅ **Deploy automático via GitHub Actions** - CI/CD para PostgreSQL VPS

## 📁 Estrutura do Projeto

```
bni-gestao-imobiliaria/
├── src/
│   ├── api/                    # REST API (FastAPI)
│   │   └── main.py
│   ├── sync/                   # Sincronização
│   │   ├── hf_sync.py         # Hugging Face Dataset sync
│   │   └── obsidian_generator.py
│   ├── validators/             # Validadores
│   │   └── csv_validator.py
│   └── reports/                # Relatórios
│       └── ifrs_reports.py
├── data/
│   ├── raw/                    # Dados brutos (CSV)
│   └── processed/              # Dados processados
├── tests/                      # Testes
├── obsidian_templates/         # Templates Obsidian
│   ├── property_template.md
│   └── portfolio_dashboard.md
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Actions workflow
├── docs/                       # Documentação
├── requirements.txt            # Dependências Python
└── setup.py                    # Configuração do pacote
```

## 🚀 Instalação

### Requisitos
- Python 3.9+
- PostgreSQL (para deploy)
- Git

### Setup Local

```bash
# Clone o repositório
git clone https://github.com/senal88/bni-gestao-imobiliaria.git
cd bni-gestao-imobiliaria

# Crie ambiente virtual
python -m venv venv
source venv/bin/activate  # Linux/Mac
# ou
venv\Scripts\activate  # Windows

# Instale dependências
pip install -r requirements.txt

# Instale o pacote em modo desenvolvimento
pip install -e .
```

## 📊 Uso

### 1. Validação de CSV

Valide o schema do arquivo CSV de propriedades:

```bash
python src/validators/csv_validator.py data/raw/properties.csv
```

### 2. API REST

Inicie o servidor da API:

```bash
python src/api/main.py
```

A API estará disponível em `http://localhost:8000`

Endpoints disponíveis:
- `GET /` - Informações da API
- `GET /properties` - Lista todas as propriedades (com filtros opcionais)
- `GET /properties/{property_id}` - Detalhes de uma propriedade
- `GET /stats` - Estatísticas do portfólio
- `GET /health` - Health check

Documentação interativa: `http://localhost:8000/docs`

### 3. Sincronização com Hugging Face

Configure seu token do Hugging Face:

```bash
export HF_TOKEN="seu_token_aqui"
export HF_DATASET_NAME="seu_usuario/bni-properties"
```

Sincronize os dados:

```bash
python src/sync/hf_sync.py data/raw/properties.csv seu_usuario/bni-properties
```

### 4. Geração de Relatórios IFRS

Gere relatórios financeiros em PDF e Excel:

```bash
# Gerar ambos os formatos
python src/reports/ifrs_reports.py data/raw/properties.csv both

# Apenas PDF
python src/reports/ifrs_reports.py data/raw/properties.csv pdf

# Apenas Excel
python src/reports/ifrs_reports.py data/raw/properties.csv excel
```

Os relatórios incluem:
- Balanço Patrimonial (IAS 1)
- Demonstração de Resultado (IAS 1)
- Valoração de Propriedades (IAS 16, IAS 40)
- Schedule detalhado de propriedades (IFRS 13)

### 5. Integração com Obsidian

Gere notas Markdown para Obsidian:

```bash
python src/sync/obsidian_generator.py data/raw/properties.csv obsidian_vault
```

Isso criará:
- Uma nota para cada propriedade
- Dashboard do portfólio com estatísticas
- Links entre notas

## 🔄 CI/CD e Deploy

### GitHub Actions

O workflow `.github/workflows/deploy.yml` executa automaticamente:

1. **Validação** - Valida schema CSV e executa testes
2. **Sync Hugging Face** - Sincroniza dados com Hugging Face Dataset
3. **Deploy PostgreSQL** - Deploy para VPS com PostgreSQL
4. **Geração de Relatórios** - Gera relatórios IFRS
5. **Geração Obsidian** - Cria notas Obsidian

### Secrets Necessários

Configure os seguintes secrets no GitHub:

```yaml
# Hugging Face
HF_TOKEN: "seu_token_hf"
HF_DATASET_NAME: "usuario/dataset"

# VPS
VPS_HOST: "ip_do_servidor"
VPS_USER: "usuario_ssh"
VPS_SSH_KEY: "chave_privada_ssh"

# PostgreSQL
DB_HOST: "localhost"
DB_PORT: "5432"
DB_NAME: "bni_properties"
DB_USER: "usuario_db"
DB_PASSWORD: "senha_db"
```

## 📝 Schema CSV

O arquivo CSV deve seguir este schema:

| Campo | Tipo | Obrigatório | Validação |
|-------|------|-------------|-----------|
| id_propriedade | string | Sim | Padrão: PROP\d{3} |
| nome | string | Sim | Mínimo 1 caractere |
| tipo | string | Sim | Enum: Residencial, Comercial, Industrial, Terreno |
| endereco | string | Sim | - |
| cidade | string | Sim | - |
| estado | string | Sim | 2 caracteres |
| cep | string | Sim | Formato: 00000-000 |
| area_m2 | float | Sim | > 0 |
| valor_aquisicao | float | Sim | >= 0 |
| data_aquisicao | string | Sim | Formato: YYYY-MM-DD |
| valor_atual | float | Sim | >= 0 |
| renda_mensal | float | Não | >= 0 |
| inquilino | string | Não | - |
| status | string | Sim | Enum: Ocupada, Vaga, Em Reforma, À Venda |

## 🧪 Testes

Execute os testes:

```bash
pytest tests/ -v
```

Com cobertura:

```bash
pytest tests/ --cov=src --cov-report=html
```

## 📖 Documentação da API

### Filtros Disponíveis

```bash
# Filtrar por tipo
curl "http://localhost:8000/properties?tipo=Comercial"

# Filtrar por estado
curl "http://localhost:8000/properties?estado=SP"

# Filtrar por status
curl "http://localhost:8000/properties?status=Ocupada"

# Filtrar por faixa de valor
curl "http://localhost:8000/properties?min_valor=500000&max_valor=1000000"

# Combinar filtros
curl "http://localhost:8000/properties?tipo=Residencial&estado=SP&status=Ocupada"
```

### Estatísticas do Portfólio

```bash
curl "http://localhost:8000/stats"
```

Retorna:
- Total de propriedades
- Valor total do portfólio
- Renda mensal total
- Contagem por status (ocupadas/vagas)
- Distribuição por tipo
- Distribuição por estado

## 🔒 Segurança

- Tokens e credenciais devem ser armazenados como secrets do GitHub
- Use variáveis de ambiente para configurações sensíveis
- Mantenha o dataset do Hugging Face como privado
- Configure firewall e SSL/TLS no VPS PostgreSQL

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📞 Suporte

Para questões e suporte:
- Abra uma [issue](https://github.com/senal88/bni-gestao-imobiliaria/issues)
- Entre em contato com a equipe BNI

## 🗺️ Roadmap

- [ ] Dashboard web interativo
- [ ] Integração com APIs de avaliação de imóveis
- [ ] Sistema de notificações (vencimento de contratos, etc)
- [ ] Mobile app
- [ ] Análise preditiva de valorização
- [ ] Integração com sistemas contábeis

---

**Desenvolvido para BNI** - Sistema de Gestão de Portfólio Imobiliário
