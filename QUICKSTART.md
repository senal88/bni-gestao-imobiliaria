# Quick Start Guide - BNI Gestão Imobiliária

## 🚀 5-Minute Setup

### 1. Prerequisites
```bash
# Check Python version (3.9+ required)
python --version
```

### 2. Clone and Install
```bash
git clone https://github.com/senal88/bni-gestao-imobiliaria.git
cd bni-gestao-imobiliaria

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
# or: venv\Scripts\activate  # Windows

# Install dependencies
pip install -r requirements.txt
```

### 3. Basic Usage

#### Validate Your Data
```bash
# Check if your CSV is valid
python main.py validate data/raw/properties.csv
```

#### Start the API
```bash
# Start REST API server
python main.py api

# In another terminal, test it:
curl http://localhost:8000/
curl http://localhost:8000/stats
curl http://localhost:8000/properties

# Interactive docs at: http://localhost:8000/docs
```

#### Generate Reports
```bash
# Generate PDF and Excel reports
python main.py reports data/raw/properties.csv --format both

# Check reports/ directory for output
ls -l reports/
```

#### Create Obsidian Notes
```bash
# Generate Markdown notes
python main.py obsidian data/raw/properties.csv

# Notes will be in obsidian_vault/
ls -l obsidian_vault/
```

## 📝 Your Data

### CSV Format
Place your property data in `data/raw/properties.csv` following this format:

```csv
id_propriedade,nome,tipo,endereco,cidade,estado,cep,area_m2,valor_aquisicao,data_aquisicao,valor_atual,renda_mensal,inquilino,status
PROP001,My Property,Comercial,Rua ABC 123,São Paulo,SP,01234-567,100.00,100000.00,2020-01-01,150000.00,1000.00,Tenant Name,Ocupada
```

### Required Fields
- `id_propriedade`: Format PROP001, PROP002, etc.
- `tipo`: Must be one of: Residencial, Comercial, Industrial, Terreno
- `status`: Must be one of: Ocupada, Vaga, Em Reforma, À Venda
- `estado`: 2-letter state code (e.g., SP, RJ)
- `cep`: Format 00000-000
- `data_aquisicao`: Format YYYY-MM-DD

## 🔧 Common Commands

```bash
# Help
python main.py --help
python main.py validate --help
python main.py reports --help

# Validate CSV
python main.py validate data/raw/properties.csv

# Generate PDF only
python main.py reports data/raw/properties.csv --format pdf

# Generate Excel only
python main.py reports data/raw/properties.csv --format excel

# Custom output directory
python main.py reports data/raw/properties.csv --output-dir /path/to/dir

# Obsidian notes in custom directory
python main.py obsidian data/raw/properties.csv --output-dir /path/to/vault

# API on different port
python main.py api --port 9000

# API with auto-reload (development)
python main.py api --reload
```

## 🧪 Run Tests

```bash
# All tests
pytest tests/ -v

# Specific test file
pytest tests/test_api.py -v

# With coverage
pytest tests/ --cov=src --cov-report=html
```

## 🔐 Configuration

### Environment Variables
Create a `.env` file (see `.env.example`):

```bash
# Hugging Face (optional)
HF_TOKEN=your_token_here
HF_DATASET_NAME=username/dataset-name

# Database (optional)
DB_HOST=localhost
DB_PORT=5432
DB_NAME=bni_properties
DB_USER=postgres
DB_PASSWORD=your_password
```

## 📊 API Endpoints

Once the API is running on `http://localhost:8000`:

- **GET /** - API information
- **GET /health** - Health check
- **GET /properties** - List all properties
  - Query params: `tipo`, `estado`, `status`, `min_valor`, `max_valor`
- **GET /properties/{id}** - Get specific property
- **GET /stats** - Portfolio statistics

### Examples

```bash
# All properties
curl http://localhost:8000/properties

# Filter by type
curl "http://localhost:8000/properties?tipo=Comercial"

# Filter by state
curl "http://localhost:8000/properties?estado=SP"

# Filter by value range
curl "http://localhost:8000/properties?min_valor=100000&max_valor=500000"

# Portfolio stats
curl http://localhost:8000/stats | jq
```

## 📖 Next Steps

1. **Customize your data**: Edit `data/raw/properties.csv`
2. **Explore reports**: Check PDF and Excel outputs in `reports/`
3. **Try Obsidian**: Open the generated Markdown files in Obsidian
4. **Setup CI/CD**: Configure GitHub Actions secrets for automated deployment
5. **Read full docs**: See `docs/DOCUMENTATION.md` for detailed information

## 🆘 Troubleshooting

### CSV Validation Fails
- Check date format: YYYY-MM-DD
- Check CEP format: 00000-000
- Verify enum values (tipo, status)
- Ensure required fields are not empty

### API Won't Start
- Check if port 8000 is available
- Verify CSV file exists at `data/raw/properties.csv`
- Check CSV format is valid

### Reports Not Generated
- Ensure CSV is valid (run validate first)
- Check write permissions in reports directory
- Verify all dependencies are installed

### Import Errors
- Ensure you're in the virtual environment
- Run `pip install -r requirements.txt` again
- Check Python version (3.9+ required)

## 🎓 Learn More

- **Full Documentation**: `docs/DOCUMENTATION.md`
- **README**: `README.md`
- **API Docs**: http://localhost:8000/docs (when API is running)
- **GitHub**: https://github.com/senal88/bni-gestao-imobiliaria

## 🤝 Support

Need help? 
1. Check the documentation
2. Run tests to verify installation
3. Open an issue on GitHub
4. Contact BNI team

---

**Ready to manage your real estate portfolio!** 🏢✨
