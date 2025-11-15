Segue um blueprint de **repositório completo**, com:

* Template dinâmico `.html` com filtros para todas as variáveis principais.
* Geração de `.pdf` a partir do template.
* “Database padronizada” (modelo relacional alinhado ao que já desenhamos de imóveis).
* 100% de paths / configs externos via `.env`.
* Documento mestre de versão de template para reaproveitar o **data contract** em outros frontends.

Vou focar em **FastAPI + Jinja2 + WeasyPrint** (Python), totalmente agnóstico de SO (Linux / macOS / VPS / GCP).

---

## 1. Estrutura de diretórios do repositório

```text
real-estate-reporting/
├── backend/
│   └── app/
│       ├── __init__.py
│       ├── config.py
│       ├── database.py
│       ├── models.py
│       ├── schemas.py
│       ├── main.py
│       └── services/
│           ├── report_service.py
│           └── pdf_service.py
├── templates/
│   ├── base.html
│   ├── report_imobiliario.html
│   └── partials/
│       ├── header.html
│       ├── footer.html
│       └── filters.html
├── static/
│   ├── css/
│   │   └── report.css
│   └── js/
│       └── filters.js
├── scripts/
│   ├── init_db.py
│   └── generate_pdf_cli.py
├── docs/
│   └── MASTER_TEMPLATE_SPEC.md
├── data/
│   └── exemplos_reais_propriedades.json
├── .env.example
├── requirements.txt
├── README.md
└── pyproject.toml
```

---

## 2. `.env.example` (100% variáveis de ambiente)

```dotenv
# APP
REPORT_APP_NAME="Real Estate Report Generator"
REPORT_ENVIRONMENT="dev"
REPORT_TIMEZONE="America/Sao_Paulo"

# DATABASE
# Exemplo Postgres: postgresql+psycopg2://user:password@host:5432/dbname
REPORT_DATABASE_URL="postgresql+psycopg2://user:password@host:5432/dbname"

# TEMPLATE / RENDER
REPORT_TEMPLATE_VERSION="1.0.0"

# PDF
REPORT_HTML2PDF_BACKEND="weasyprint"
# Diretório de saída para PDFs (relativo ao root do repo)
REPORT_PDF_OUTPUT_DIR="output/pdf"

# SEED
REPORT_SEED_FILE="data/raw/propriedades.csv"
```

> No deploy, você copia para `.env` e ajusta valores conforme ambiente (VPS, GCP, etc.).

---

## 3. `requirements.txt`

```txt
fastapi==0.115.0
uvicorn[standard]==0.30.0
Jinja2==3.1.4
SQLAlchemy==2.0.32
psycopg2-binary==2.9.9
pydantic==2.8.2
python-dotenv==1.0.1
weasyprint==62.3
```

---

## 4. `backend/app/config.py`

```python
from pydantic import BaseSettings


class Settings(BaseSettings):
    app_name: str = "Real Estate Report Generator"
    environment: str = "dev"
    timezone: str = "America/Sao_Paulo"

    database_url: str

    template_version: str = "1.0.0"

    html2pdf_backend: str = "weasyprint"
    pdf_output_dir: str = "output/pdf"

    seed_file: str = "data/raw/propriedades.csv"

    class Config:
        env_file = ".env"
        env_prefix = "REPORT_"


settings = Settings()
```

---

## 5. `backend/app/database.py`

```python
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from .config import settings

engine = create_engine(settings.database_url, future=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine, future=True)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

---

## 6. `backend/app/models.py`

(Modelo alinhado à padronização de imóveis que montamos antes.)

```python
from sqlalchemy import (
    Column,
    String,
    Integer,
    Numeric,
    Date,
    Boolean,
    ForeignKey,
    Text
)
from sqlalchemy.orm import relationship
from .database import Base


class Familia(Base):
    __tablename__ = "dim_familia"

    id_familia = Column(String, primary_key=True)
    cod_familia = Column(String, nullable=False)
    nome_familia = Column(String, nullable=False)
    cliente_raiz = Column(String)
    gestor_principal = Column(String)

    imoveis = relationship("Imovel", back_populates="familia")


class Imovel(Base):
    __tablename__ = "dim_imovel"

    id_imovel = Column(String, primary_key=True)
    id_familia = Column(String, ForeignKey("dim_familia.id_familia"), nullable=False)

    codigo_interno = Column(String)
    nome_imovel = Column(String, nullable=False)
    tipo_ativo = Column(String, nullable=False)            # CASA, APARTAMENTO, TERRENO...
    classificacao_setor = Column(String)                   # RESIDENCIAL, COMERCIAL...
    finalidade_principal = Column(String)                  # VENDA, LOCACAO, VALORIZACAO...

    pais = Column(String, default="BR")
    uf = Column(String(2))
    cidade = Column(String)
    bairro = Column(String)
    logradouro = Column(String)
    numero = Column(String)
    complemento = Column(String)
    cep = Column(String)

    data_aquisicao = Column(Date)
    participacao_percent = Column(Numeric(5, 2))
    area_total_m2 = Column(Numeric(14, 2))
    area_privativa_m2 = Column(Numeric(14, 2))

    status_obras = Column(String)                          # CONCLUIDO, EM_ANDAMENTO, PARADO
    situacao_ocupacao_atual = Column(String)               # LOCADO, VAGO, PROPRIO, EM_OBRAS
    status_ativo = Column(String, default="ATIVO")

    observacoes = Column(Text)

    familia = relationship("Familia", back_populates="imoveis")
    valuations = relationship("ValuationImovel", back_populates="imovel")
    contratos_locacao = relationship("LocacaoContrato", back_populates="imovel")
    due_items = relationship("DueDiligenceImovel", back_populates="imovel")
    marketing_entries = relationship("MarketingImovel", back_populates="imovel")


class ValuationImovel(Base):
    __tablename__ = "fact_valuation_imovel"

    id_valuation = Column(String, primary_key=True)
    id_imovel = Column(String, ForeignKey("dim_imovel.id_imovel"), nullable=False)

    dt_referencia = Column(Date, nullable=False)
    tipo_valuation = Column(String, nullable=False)        # AQUISITIVO, MERCADO_VENDA, MERCADO_ALUGUEL
    valor = Column(Numeric(16, 2), nullable=False)
    moeda = Column(String(3), default="BRL")
    fonte = Column(String)
    valor_m2 = Column(Numeric(16, 2))
    indicador_pct = Column(Numeric(8, 4))

    imovel = relationship("Imovel", back_populates="valuations")


class LocacaoContrato(Base):
    __tablename__ = "fact_locacao_contrato"

    id_contrato = Column(String, primary_key=True)
    id_imovel = Column(String, ForeignKey("dim_imovel.id_imovel"), nullable=False)

    codigo_contrato = Column(String)
    locatario_nome = Column(String)
    locatario_tipo = Column(String)                        # PF, PJ
    administrador_imobiliaria = Column(String)

    data_inicio = Column(Date, nullable=False)
    data_fim_prevista = Column(Date)
    data_fim_efetiva = Column(Date)
    situacao_contrato = Column(String)                     # ATIVO, ENCERRADO...

    valor_aluguel_mensal_bruto = Column(Numeric(16, 2))
    valor_aluguel_mensal_liquido = Column(Numeric(16, 2))
    valor_aluguel_mercado_mensal = Column(Numeric(16, 2))

    indice_reajuste = Column(String)
    periodicidade_reajuste_meses = Column(Integer)
    dia_vencimento = Column(Integer)

    retorno_aluguel_pct = Column(Numeric(8, 4))

    imovel = relationship("Imovel", back_populates="contratos_locacao")


class DueDiligenceImovel(Base):
    __tablename__ = "fact_due_diligence_imovel"

    id_due = Column(String, primary_key=True)
    id_imovel = Column(String, ForeignKey("dim_imovel.id_imovel"), nullable=False)

    dt_referencia = Column(Date, nullable=False)
    tipo_item = Column(String, nullable=False)             # TITULARIDADE_SPU, MATRICULA, HABITE_SE...
    descricao = Column(Text)
    status = Column(String, nullable=False)                # EM_ANDAMENTO, CONCLUIDO...
    criticidade = Column(String)                           # URGENTE, MEDIA, BAIXA
    responsavel = Column(String)
    dt_prazo = Column(Date)
    dt_conclusao = Column(Date)
    observacoes = Column(Text)

    imovel = relationship("Imovel", back_populates="due_items")


class MarketingImovel(Base):
    __tablename__ = "fact_marketing_imovel"

    id_marketing = Column(String, primary_key=True)
    id_imovel = Column(String, ForeignKey("dim_imovel.id_imovel"), nullable=False)

    dt_referencia = Column(Date, nullable=False)
    finalidade = Column(String, nullable=False)            # VENDA, LOCACAO

    qtd_imobiliarias = Column(Integer)
    plataformas = Column(Text)

    visualizacoes = Column(Integer)
    visitas = Column(Integer)
    propostas = Column(Integer)
    propostas_aceitas = Column(Integer)

    status_negociacao = Column(String)

    imovel = relationship("Imovel", back_populates="marketing_entries")
```

---

## 7. `backend/app/schemas.py` (Pydantic – payloads / view models)

```python
from datetime import date
from decimal import Decimal
from pydantic import BaseModel


class FiltroImoveis(BaseModel):
    familia_id: str | None = None
    cidade: str | None = None
    classificacao_setor: str | None = None
    tipo_ativo: str | None = None
    finalidade_principal: str | None = None
    situacao_ocupacao_atual: str | None = None
    status_obras: str | None = None
    data_referencia: date | None = None


class ResumoCarteira(BaseModel):
    qtd_imoveis: int
    valor_mercado_total: Decimal
    valor_aquisitivo_total: Decimal
    receita_locacao_mensal: Decimal
```

---

## 8. `backend/app/services/report_service.py`

```python
from decimal import Decimal
from typing import Iterable
from sqlalchemy.orm import Session
from sqlalchemy import func, select
from .. import models
from . import pdf_service  # se quiser reaproveitar helpers
from ..schemas import FiltroImoveis, ResumoCarteira


def aplicar_filtros_imoveis(query, filtros: FiltroImoveis):
    if filtros.familia_id:
        query = query.filter(models.Imovel.id_familia == filtros.familia_id)
    if filtros.cidade:
        query = query.filter(models.Imovel.cidade == filtros.cidade)
    if filtros.classificacao_setor:
        query = query.filter(models.Imovel.classificacao_setor == filtros.classificacao_setor)
    if filtros.tipo_ativo:
        query = query.filter(models.Imovel.tipo_ativo == filtros.tipo_ativo)
    if filtros.finalidade_principal:
        query = query.filter(models.Imovel.finalidade_principal == filtros.finalidade_principal)
    if filtros.situacao_ocupacao_atual:
        query = query.filter(models.Imovel.situacao_ocupacao_atual == filtros.situacao_ocupacao_atual)
    if filtros.status_obras:
        query = query.filter(models.Imovel.status_obras == filtros.status_obras)
    return query


def listar_imoveis(db: Session, filtros: FiltroImoveis) -> Iterable[models.Imovel]:
    query = db.query(models.Imovel)
    query = aplicar_filtros_imoveis(query, filtros)
    return query.order_by(models.Imovel.nome_imovel).all()


def calcular_resumo(db: Session, filtros: FiltroImoveis) -> ResumoCarteira:
    imoveis_query = db.query(models.Imovel.id_imovel)
    imoveis_query = aplicar_filtros_imoveis(imoveis_query, filtros)
    imovel_ids = [r.id_imovel for r in imoveis_query.all()]
    if not imovel_ids:
        return ResumoCarteira(
            qtd_imoveis=0,
            valor_mercado_total=Decimal("0.00"),
            valor_aquisitivo_total=Decimal("0.00"),
            receita_locacao_mensal=Decimal("0.00"),
        )

    sub_valuation = (
        db.query(
            models.ValuationImovel.id_imovel,
            func.max(models.ValuationImovel.dt_referencia).label("max_dt")
        )
        .filter(models.ValuationImovel.id_imovel.in_(imovel_ids))
        .group_by(models.ValuationImovel.id_imovel)
        .subquery()
    )

    valor_mercado_total = (
        db.query(func.coalesce(func.sum(models.ValuationImovel.valor), 0))
        .join(
            sub_valuation,
            (models.ValuationImovel.id_imovel == sub_valuation.c.id_imovel)
            & (models.ValuationImovel.dt_referencia == sub_valuation.c.max_dt)
        )
        .filter(models.ValuationImovel.tipo_valuation == "MERCADO_VENDA")
        .scalar()
    )

    valor_aquisitivo_total = (
        db.query(func.coalesce(func.sum(models.ValuationImovel.valor), 0))
        .filter(
            models.ValuationImovel.id_imovel.in_(imovel_ids),
            models.ValuationImovel.tipo_valuation == "AQUISITIVO",
        )
        .scalar()
    )

    receita_locacao_mensal = (
        db.query(func.coalesce(func.sum(models.LocacaoContrato.valor_aluguel_mensal_liquido), 0))
        .filter(
            models.LocacaoContrato.id_imovel.in_(imovel_ids),
            models.LocacaoContrato.situacao_contrato == "ATIVO",
        )
        .scalar()
    )

    qtd_imoveis = len(imovel_ids)

    return ResumoCarteira(
        qtd_imoveis=qtd_imoveis,
        valor_mercado_total=Decimal(valor_mercado_total),
        valor_aquisitivo_total=Decimal(valor_aquisitivo_total),
        receita_locacao_mensal=Decimal(receita_locacao_mensal),
    )


def obter_opcoes_filtros(db: Session):
    return {
        "familias": db.query(models.Familia).order_by(models.Familia.nome_familia).all(),
        "cidades": [r[0] for r in db.query(models.Imovel.cidade).distinct().order_by(models.Imovel.cidade).all() if r[0]],
        "classificacoes_setor": [r[0] for r in db.query(models.Imovel.classificacao_setor).distinct().all() if r[0]],
        "tipos_ativos": [r[0] for r in db.query(models.Imovel.tipo_ativo).distinct().all() if r[0]],
        "finalidades": [r[0] for r in db.query(models.Imovel.finalidade_principal).distinct().all() if r[0]],
        "situacoes_ocupacao": [r[0] for r in db.query(models.Imovel.situacao_ocupacao_atual).distinct().all() if r[0]],
        "status_obras": [r[0] for r in db.query(models.Imovel.status_obras).distinct().all() if r[0]],
    }
```

---

## 9. `backend/app/services/pdf_service.py`

```python
from pathlib import Path
from typing import Dict, Any
from weasyprint import HTML
from jinja2 import Environment, FileSystemLoader, select_autoescape
from ..config import settings

BASE_DIR = Path(__file__).resolve().parents[2]
TEMPLATES_DIR = BASE_DIR / "templates"
OUTPUT_DIR = BASE_DIR / settings.pdf_output_dir

env = Environment(
    loader=FileSystemLoader(str(TEMPLATES_DIR)),
    autoescape=select_autoescape(["html", "xml"])
)


def render_html(template_name: str, context: Dict[str, Any]) -> str:
    template = env.get_template(template_name)
    return template.render(**context)


def html_to_pdf_bytes(html_content: str) -> bytes:
    pdf = HTML(string=html_content, base_url=str(TEMPLATES_DIR)).write_pdf()
    return pdf


def save_pdf_file(filename: str, pdf_bytes: bytes) -> Path:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    pdf_path = OUTPUT_DIR / filename
    pdf_path.write_bytes(pdf_bytes)
    return pdf_path
```

---

## 10. `backend/app/main.py` (API / HTML / PDF)

```python
from fastapi import FastAPI, Depends, Request, Response, Query
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from pathlib import Path
from uuid import uuid4
from .config import settings
from .database import get_db, Base, engine
from . import models
from .schemas import FiltroImoveis
from .services import report_service, pdf_service

Base.metadata.create_all(bind=engine)

BASE_DIR = Path(__file__).resolve().parents[2]
templates = Jinja2Templates(directory=str(BASE_DIR / "templates"))

app = FastAPI(title=settings.app_name)

app.mount("/static", StaticFiles(directory=str(BASE_DIR / "static")), name="static")


@app.get("/health", tags=["infra"])
def healthcheck():
    return {"status": "ok", "env": settings.environment}


@app.get("/report/imoveis", response_class=HTMLResponse, tags=["html"])
def report_imoveis(
    request: Request,
    familia_id: str | None = Query(default=None),
    cidade: str | None = Query(default=None),
    classificacao_setor: str | None = Query(default=None),
    tipo_ativo: str | None = Query(default=None),
    finalidade_principal: str | None = Query(default=None),
    situacao_ocupacao_atual: str | None = Query(default=None),
    status_obras: str | None = Query(default=None),
    db=Depends(get_db),
):
    filtros = FiltroImoveis(
        familia_id=familia_id,
        cidade=cidade,
        classificacao_setor=classificacao_setor,
        tipo_ativo=tipo_ativo,
        finalidade_principal=finalidade_principal,
        situacao_ocupacao_atual=situacao_ocupacao_atual,
        status_obras=status_obras,
    )

    imoveis = report_service.listar_imoveis(db, filtros)
    resumo = report_service.calcular_resumo(db, filtros)
    opcoes = report_service.obter_opcoes_filtros(db)

    context = {
        "request": request,
        "template_version": settings.template_version,
        "filtros": filtros,
        "imoveis": imoveis,
        "resumo": resumo,
        "opcoes": opcoes,
    }

    return templates.TemplateResponse("report_imobiliario.html", context)


@app.get("/report/imoveis/pdf", tags=["pdf"])
def report_imoveis_pdf(
    request: Request,
    familia_id: str | None = Query(default=None),
    cidade: str | None = Query(default=None),
    classificacao_setor: str | None = Query(default=None),
    tipo_ativo: str | None = Query(default=None),
    finalidade_principal: str | None = Query(default=None),
    situacao_ocupacao_atual: str | None = Query(default=None),
    status_obras: str | None = Query(default=None),
    db=Depends(get_db),
):
    filtros = FiltroImoveis(
        familia_id=familia_id,
        cidade=cidade,
        classificacao_setor=classificacao_setor,
        tipo_ativo=tipo_ativo,
        finalidade_principal=finalidade_principal,
        situacao_ocupacao_atual=situacao_ocupacao_atual,
        status_obras=status_obras,
    )

    imoveis = report_service.listar_imoveis(db, filtros)
    resumo = report_service.calcular_resumo(db, filtros)
    opcoes = report_service.obter_opcoes_filtros(db)

    context = {
        "request": request,
        "template_version": settings.template_version,
        "filtros": filtros,
        "imoveis": imoveis,
        "resumo": resumo,
        "opcoes": opcoes,
    }

    html_content = pdf_service.render_html("report_imobiliario.html", context)
    pdf_bytes = pdf_service.html_to_pdf_bytes(html_content)

    filename = f"relatorio_imobiliario_{uuid4().hex}.pdf"
    pdf_service.save_pdf_file(filename, pdf_bytes)

    headers = {
        "Content-Disposition": f'attachment; filename="{filename}"'
    }
    return Response(content=pdf_bytes, media_type="application/pdf", headers=headers)
```

---

## 11. `templates/base.html`

```html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <title>{% block title %}Relatório Imobiliário{% endblock %}</title>
    <link rel="stylesheet" href="/static/css/report.css">
    <script defer src="/static/js/filters.js"></script>
</head>
<body>
<header>
    {% include 'partials/header.html' %}
</header>

<main>
    {% block content %}{% endblock %}
</main>

<footer>
    {% include 'partials/footer.html' %}
</footer>
</body>
</html>
```

---

## 12. `templates/partials/header.html`

```html
<div class="header">
    <div class="brand">
        <h1>Gestão de Patrimônio – Relatório Imobiliário</h1>
        <span class="brand-subtitle">Template versão {{ template_version }}</span>
    </div>
</div>
```

---

## 13. `templates/partials/footer.html`

```html
<div class="footer">
    <span>Relatório gerado automaticamente. Uso interno do Multi-Family Office.</span>
</div>
```

---

## 14. `templates/partials/filters.html`

(Filtros completos para as principais variáveis do HTML)

```html
<form id="filter-form" method="get" class="filters">
    <div class="filter-group">
        <label for="familia_id">Família</label>
        <select name="familia_id" id="familia_id">
            <option value="">Todas</option>
            {% for familia in opcoes.familias %}
                <option value="{{ familia.id_familia }}"
                        {% if filtros.familia_id == familia.id_familia %}selected{% endif %}>
                    {{ familia.nome_familia }}
                </option>
            {% endfor %}
        </select>
    </div>

    <div class="filter-group">
        <label for="cidade">Cidade</label>
        <select name="cidade" id="cidade">
            <option value="">Todas</option>
            {% for c in opcoes.cidades %}
                <option value="{{ c }}" {% if filtros.cidade == c %}selected{% endif %}>{{ c }}</option>
            {% endfor %}
        </select>
    </div>

    <div class="filter-group">
        <label for="classificacao_setor">Setor</label>
        <select name="classificacao_setor" id="classificacao_setor">
            <option value="">Todos</option>
            {% for s in opcoes.classificacoes_setor %}
                <option value="{{ s }}" {% if filtros.classificacao_setor == s %}selected{% endif %}>{{ s }}</option>
            {% endfor %}
        </select>
    </div>

    <div class="filter-group">
        <label for="tipo_ativo">Tipo de Imóvel</label>
        <select name="tipo_ativo" id="tipo_ativo">
            <option value="">Todos</option>
            {% for t in opcoes.tipos_ativos %}
                <option value="{{ t }}" {% if filtros.tipo_ativo == t %}selected{% endif %}>{{ t }}</option>
            {% endfor %}
        </select>
    </div>

    <div class="filter-group">
        <label for="finalidade_principal">Finalidade</label>
        <select name="finalidade_principal" id="finalidade_principal">
            <option value="">Todas</option>
            {% for f in opcoes.finalidades %}
                <option value="{{ f }}" {% if filtros.finalidade_principal == f %}selected{% endif %}>{{ f }}</option>
            {% endfor %}
        </select>
    </div>

    <div class="filter-group">
        <label for="situacao_ocupacao_atual">Situação de Ocupação</label>
        <select name="situacao_ocupacao_atual" id="situacao_ocupacao_atual">
            <option value="">Todas</option>
            {% for s in opcoes.situacoes_ocupacao %}
                <option value="{{ s }}" {% if filtros.situacao_ocupacao_atual == s %}selected{% endif %}>{{ s }}</option>
            {% endfor %}
        </select>
    </div>

    <div class="filter-group">
        <label for="status_obras">Status de Obras</label>
        <select name="status_obras" id="status_obras">
            <option value="">Todos</option>
            {% for s in opcoes.status_obras %}
                <option value="{{ s }}" {% if filtros.status_obras == s %}selected{% endif %}>{{ s }}</option>
            {% endfor %}
        </select>
    </div>

    <div class="filter-actions">
        <button type="submit">Aplicar filtros</button>
        <a href="/report/imoveis" class="button-secondary">Limpar</a>
        <a href="/report/imoveis/pdf?{{ request.query_params }}" class="button-primary">
            Baixar PDF
        </a>
    </div>
</form>
```

---

## 15. `templates/report_imobiliario.html`

```html
{% extends "base.html" %}

{% block title %}Relatório Imobiliário{% endblock %}

{% block content %}

<section class="filters-section">
    {% include 'partials/filters.html' %}
</section>

<section class="summary-section">
    <h2>Síntese dos Investimentos Imobiliários</h2>
    <div class="summary-cards">
        <div class="card">
            <span class="label">Qtd. Imóveis</span>
            <span class="value">{{ resumo.qtd_imoveis }}</span>
        </div>
        <div class="card">
            <span class="label">Valor de Mercado Total</span>
            <span class="value">R$ {{ "%.2f"|format(resumo.valor_mercado_total) }}</span>
        </div>
        <div class="card">
            <span class="label">Valor Aquisitivo Total</span>
            <span class="value">R$ {{ "%.2f"|format(resumo.valor_aquisitivo_total) }}</span>
        </div>
        <div class="card">
            <span class="label">Receita de Locação Mensal</span>
            <span class="value">R$ {{ "%.2f"|format(resumo.receita_locacao_mensal) }}</span>
        </div>
    </div>
</section>

<section class="table-section">
    <h2>Composição Imobiliária</h2>
    <table class="imoveis-table">
        <thead>
        <tr>
            <th>Família</th>
            <th>Imóvel</th>
            <th>Tipo</th>
            <th>Setor</th>
            <th>Finalidade</th>
            <th>Cidade</th>
            <th>UF</th>
            <th>Área Total (m²)</th>
            <th>Área Privativa (m²)</th>
            <th>Valor Aquisitivo</th>
            <th>Valor Mercado</th>
            <th>Situação</th>
        </tr>
        </thead>
        <tbody>
        {% for imovel in imoveis %}
            {% set val_aquisitivo = (imovel.valuations | selectattr("tipo_valuation", "equalto", "AQUISITIVO") | list) %}
            {% set val_mercado = (imovel.valuations | selectattr("tipo_valuation", "equalto", "MERCADO_VENDA") | list) %}
            <tr>
                <td>{{ imovel.familia.nome_familia if imovel.familia else "-" }}</td>
                <td>{{ imovel.nome_imovel }}</td>
                <td>{{ imovel.tipo_ativo }}</td>
                <td>{{ imovel.classificacao_setor }}</td>
                <td>{{ imovel.finalidade_principal }}</td>
                <td>{{ imovel.cidade }}</td>
                <td>{{ imovel.uf }}</td>
                <td>{{ "%.2f"|format(imovel.area_total_m2 or 0) }}</td>
                <td>{{ "%.2f"|format(imovel.area_privativa_m2 or 0) }}</td>
                <td>
                    {% if val_aquisitivo %}
                        R$ {{ "%.2f"|format(val_aquisitivo[0].valor) }}
                    {% else %}
                        -
                    {% endif %}
                </td>
                <td>
                    {% if val_mercado %}
                        R$ {{ "%.2f"|format(val_mercado[0].valor) }}
                    {% else %}
                        -
                    {% endif %}
                </td>
                <td>{{ imovel.situacao_ocupacao_atual }}</td>
            </tr>
        {% endfor %}
        </tbody>
    </table>
</section>

<section class="due-section">
    <h2>Due Diligence – Pendências / Andamentos</h2>
    <table class="due-table">
        <thead>
        <tr>
            <th>Imóvel</th>
            <th>Tipo</th>
            <th>Status</th>
            <th>Criticidade</th>
            <th>Responsável</th>
            <th>Prazo</th>
            <th>Descrição</th>
        </tr>
        </thead>
        <tbody>
        {% for imovel in imoveis %}
            {% for due in imovel.due_items %}
                <tr>
                    <td>{{ imovel.nome_imovel }}</td>
                    <td>{{ due.tipo_item }}</td>
                    <td>{{ due.status }}</td>
                    <td>{{ due.criticidade }}</td>
                    <td>{{ due.responsavel }}</td>
                    <td>{{ due.dt_prazo or "" }}</td>
                    <td>{{ due.descricao }}</td>
                </tr>
            {% endfor %}
        {% endfor %}
        </tbody>
    </table>
</section>

<section class="marketing-section">
    <h2>Movimentação Comercial – Visualizações, Visitas e Propostas</h2>
    <table class="marketing-table">
        <thead>
        <tr>
            <th>Imóvel</th>
            <th>Finalidade</th>
            <th>Data Referência</th>
            <th>Imobiliárias</th>
            <th>Visualizações</th>
            <th>Visitas</th>
            <th>Propostas</th>
            <th>Propostas Aceitas</th>
            <th>Status Negociação</th>
        </tr>
        </thead>
        <tbody>
        {% for imovel in imoveis %}
            {% for mk in imovel.marketing_entries %}
                <tr>
                    <td>{{ imovel.nome_imovel }}</td>
                    <td>{{ mk.finalidade }}</td>
                    <td>{{ mk.dt_referencia }}</td>
                    <td>{{ mk.qtd_imobiliarias }}</td>
                    <td>{{ mk.visualizacoes }}</td>
                    <td>{{ mk.visitas }}</td>
                    <td>{{ mk.propostas }}</td>
                    <td>{{ mk.propostas_aceitas }}</td>
                    <td>{{ mk.status_negociacao }}</td>
                </tr>
            {% endfor %}
        {% endfor %}
        </tbody>
    </table>
</section>

{% endblock %}
```

---

## 16. `static/css/report.css` (estilização básica, ready to PDF)

```css
body {
    font-family: Arial, sans-serif;
    font-size: 12px;
    margin: 0;
    padding: 0;
}

.header, .footer {
    padding: 12px 24px;
    background: #f5f5f5;
}

.header h1 {
    margin: 0;
    font-size: 18px;
}

.brand-subtitle {
    font-size: 10px;
    color: #666;
}

.filters-section, .summary-section, .table-section, .due-section, .marketing-section {
    padding: 16px 24px;
}

.filters {
    display: flex;
    flex-wrap: wrap;
    gap: 12px;
    align-items: flex-end;
}

.filter-group {
    display: flex;
    flex-direction: column;
    min-width: 180px;
}

.filter-group label {
    font-size: 11px;
    margin-bottom: 4px;
}

.filter-group select {
    padding: 4px;
    font-size: 12px;
}

.filter-actions {
    display: flex;
    gap: 8px;
}

button, .button-secondary, .button-primary {
    padding: 6px 12px;
    border-radius: 4px;
    border: 1px solid #ccc;
    text-decoration: none;
    font-size: 12px;
}

.button-primary {
    border-color: #004aad;
}

.summary-cards {
    display: flex;
    gap: 16px;
    flex-wrap: wrap;
}

.summary-cards .card {
    border: 1px solid #ddd;
    padding: 8px 12px;
    border-radius: 4px;
    min-width: 200px;
}

.summary-cards .label {
    font-size: 11px;
    color: #666;
}

.summary-cards .value {
    display: block;
    font-weight: bold;
    margin-top: 4px;
}

table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 12px;
    font-size: 11px;
}

table th, table td {
    border: 1px solid #ddd;
    padding: 4px 6px;
}

table th {
    background: #f0f0f0;
}
```

---

## 17. `static/js/filters.js`

```javascript
document.addEventListener("DOMContentLoaded", function () {
    const form = document.getElementById("filter-form");
    if (!form) return;

    // espaço reservado para validações futuras de filtros no front-end
});
```

---

## 18. `scripts/init_db.py`

(Seed da base a partir de JSON padronizado – database padronizada ↔ template)

```python
import json
from pathlib import Path
from uuid import uuid4
from backend.app.database import Base, engine, SessionLocal
from backend.app.config import settings
from backend.app import models

Base.metadata.create_all(bind=engine)


def main():
    seed_path = Path(settings.seed_file)
    if not seed_path.exists():
        print(f"Seed file not found: {seed_path}")
        return

    data = json.loads(seed_path.read_text(encoding="utf-8"))

    db = SessionLocal()
    try:
        for familia_data in data.get("familias", []):
            familia = models.Familia(
                id_familia=familia_data["id_familia"],
                cod_familia=familia_data["cod_familia"],
                nome_familia=familia_data["nome_familia"],
                cliente_raiz=familia_data.get("cliente_raiz"),
                gestor_principal=familia_data.get("gestor_principal"),
            )
            db.merge(familia)

        for imovel_data in data.get("imoveis", []):
            imovel = models.Imovel(
                id_imovel=imovel_data["id_imovel"],
                id_familia=imovel_data["id_familia"],
                codigo_interno=imovel_data.get("codigo_interno"),
                nome_imovel=imovel_data["nome_imovel"],
                tipo_ativo=imovel_data["tipo_ativo"],
                classificacao_setor=imovel_data.get("classificacao_setor"),
                finalidade_principal=imovel_data.get("finalidade_principal"),
                pais=imovel_data.get("pais", "BR"),
                uf=imovel_data.get("uf"),
                cidade=imovel_data.get("cidade"),
                bairro=imovel_data.get("bairro"),
                logradouro=imovel_data.get("logradouro"),
                numero=imovel_data.get("numero"),
                complemento=imovel_data.get("complemento"),
                cep=imovel_data.get("cep"),
                data_aquisicao=imovel_data.get("data_aquisicao"),
                participacao_percent=imovel_data.get("participacao_percent"),
                area_total_m2=imovel_data.get("area_total_m2"),
                area_privativa_m2=imovel_data.get("area_privativa_m2"),
                status_obras=imovel_data.get("status_obras"),
                situacao_ocupacao_atual=imovel_data.get("situacao_ocupacao_atual"),
                status_ativo=imovel_data.get("status_ativo", "ATIVO"),
                observacoes=imovel_data.get("observacoes"),
            )
            db.merge(imovel)

        for val in data.get("valuations", []):
            v = models.ValuationImovel(
                id_valuation=val.get("id_valuation", uuid4().hex),
                id_imovel=val["id_imovel"],
                dt_referencia=val["dt_referencia"],
                tipo_valuation=val["tipo_valuation"],
                valor=val["valor"],
                moeda=val.get("moeda", "BRL"),
                fonte=val.get("fonte"),
                valor_m2=val.get("valor_m2"),
                indicador_pct=val.get("indicador_pct"),
            )
            db.merge(v)

        for c in data.get("contratos_locacao", []):
            contrato = models.LocacaoContrato(
                id_contrato=c.get("id_contrato", uuid4().hex),
                id_imovel=c["id_imovel"],
                codigo_contrato=c.get("codigo_contrato"),
                locatario_nome=c.get("locatario_nome"),
                locatario_tipo=c.get("locatario_tipo"),
                administrador_imobiliaria=c.get("administrador_imobiliaria"),
                data_inicio=c["data_inicio"],
                data_fim_prevista=c.get("data_fim_prevista"),
                data_fim_efetiva=c.get("data_fim_efetiva"),
                situacao_contrato=c.get("situacao_contrato"),
                valor_aluguel_mensal_bruto=c.get("valor_aluguel_mensal_bruto"),
                valor_aluguel_mensal_liquido=c.get("valor_aluguel_mensal_liquido"),
                valor_aluguel_mercado_mensal=c.get("valor_aluguel_mercado_mensal"),
                indice_reajuste=c.get("indice_reajuste"),
                periodicidade_reajuste_meses=c.get("periodicidade_reajuste_meses"),
                dia_vencimento=c.get("dia_vencimento"),
                retorno_aluguel_pct=c.get("retorno_aluguel_pct"),
            )
            db.merge(contrato)

        for d in data.get("due_diligence", []):
            due = models.DueDiligenceImovel(
                id_due=d.get("id_due", uuid4().hex),
                id_imovel=d["id_imovel"],
                dt_referencia=d["dt_referencia"],
                tipo_item=d["tipo_item"],
                descricao=d.get("descricao"),
                status=d["status"],
                criticidade=d.get("criticidade"),
                responsavel=d.get("responsavel"),
                dt_prazo=d.get("dt_prazo"),
                dt_conclusao=d.get("dt_conclusao"),
                observacoes=d.get("observacoes"),
            )
            db.merge(due)

        for m in data.get("marketing", []):
            mk = models.MarketingImovel(
                id_marketing=m.get("id_marketing", uuid4().hex),
                id_imovel=m["id_imovel"],
                dt_referencia=m["dt_referencia"],
                finalidade=m["finalidade"],
                qtd_imobiliarias=m.get("qtd_imobiliarias"),
                plataformas=m.get("plataformas"),
                visualizacoes=m.get("visualizacoes"),
                visitas=m.get("visitas"),
                propostas=m.get("propostas"),
                propostas_aceitas=m.get("propostas_aceitas"),
                status_negociacao=m.get("status_negociacao"),
            )
            db.merge(mk)

        db.commit()
        print("Seed concluído.")
    finally:
        db.close()


if __name__ == "__main__":
    main()
```

---

## 19. `scripts/generate_pdf_cli.py`

(CLI para rodar geração de PDF sem HTTP – útil para automação n8n/Make/etc.)

```python
from uuid import uuid4
from pathlib import Path
from backend.app.database import SessionLocal
from backend.app.config import settings
from backend.app.schemas import FiltroImoveis
from backend.app.services import report_service, pdf_service


def main():
    db = SessionLocal()
    try:
        filtros = FiltroImoveis()
        imoveis = report_service.listar_imoveis(db, filtros)
        resumo = report_service.calcular_resumo(db, filtros)
        opcoes = report_service.obter_opcoes_filtros(db)

        context = {
            "request": None,  # não usado na renderização offline
            "template_version": settings.template_version,
            "filtros": filtros,
            "imoveis": imoveis,
            "resumo": resumo,
            "opcoes": opcoes,
        }

        html_content = pdf_service.render_html("report_imobiliario.html", context)
        pdf_bytes = pdf_service.html_to_pdf_bytes(html_content)
        filename = f"relatorio_imobiliario_cli_{uuid4().hex}.pdf"
        pdf_path = pdf_service.save_pdf_file(filename, pdf_bytes)

        print(f"PDF gerado: {pdf_path}")
    finally:
        db.close()


if __name__ == "__main__":
    main()
```

---

## 20. `docs/MASTER_TEMPLATE_SPEC.md`

(**Documento mestre de versões / contrato de dados → conversão para outros frontends**)

````md
# MASTER TEMPLATE SPEC – REAL_ESTATE_PORTFOLIO

## 1. Escopo

Este documento define o contrato de dados e as versões de desenvolvimento
do template **REAL_ESTATE_PORTFOLIO** utilizado para renderizar:

- Relatório dinâmico em HTML
- Exportação em PDF
- Outras camadas de frontend (React, Vue, Appsmith, Dify, etc.) reutilizando o mesmo payload.

## 2. Identificação do Template

- Template family: `REAL_ESTATE_PORTFOLIO`
- Template id: `REAL_ESTATE_PORTFOLIO_DEFAULT`
- Versão atual: `1.0.0`

### 2.1. Política de versionamento

- `MAJOR`: quebra de contrato (mudança estrutural em campos obrigatórios).
- `MINOR`: novos campos opcionais, novas seções no HTML.
- `PATCH`: ajustes visuais ou correção de cálculo sem alterar o contrato.

## 3. Contrato de Dados (Data Contract)

Payload consolidado que alimenta qualquer frontend:

```jsonc
{
  "template_family": "REAL_ESTATE_PORTFOLIO",
  "template_id": "REAL_ESTATE_PORTFOLIO_DEFAULT",
  "template_version": "1.0.0",

  "filtros_aplicados": {
    "familia_id": "string|null",
    "cidade": "string|null",
    "classificacao_setor": "string|null",
    "tipo_ativo": "string|null",
    "finalidade_principal": "string|null",
    "situacao_ocupacao_atual": "string|null",
    "status_obras": "string|null",
    "data_referencia": "YYYY-MM-DD|null"
  },

  "resumo": {
    "qtd_imoveis": "number",
    "valor_mercado_total": "number",
    "valor_aquisitivo_total": "number",
    "receita_locacao_mensal": "number"
  },

  "imoveis": [
    {
      "id_imovel": "string",
      "familia": {
        "id_familia": "string",
        "nome_familia": "string"
      },
      "tipo_ativo": "string",
      "classificacao_setor": "string",
      "finalidade_principal": "string",
      "cidade": "string",
      "uf": "string",
      "area_total_m2": "number",
      "area_privativa_m2": "number",
      "situacao_ocupacao_atual": "string",
      "status_obras": "string",

      "valuation_aquisitivo": {
        "dt_referencia": "YYYY-MM-DD",
        "valor": "number"
      },
      "valuation_mercado": {
        "dt_referencia": "YYYY-MM-DD",
        "valor": "number",
        "valor_m2": "number"
      },

      "contrato_locacao_ativo": {
        "locatario_nome": "string",
        "administrador_imobiliaria": "string",
        "valor_aluguel_mensal_liquido": "number",
        "valor_aluguel_mercado_mensal": "number",
        "retorno_aluguel_pct": "number"
      },

      "due_diligence": [
        {
          "tipo_item": "string",
          "status": "string",
          "criticidade": "string",
          "responsavel": "string",
          "dt_prazo": "YYYY-MM-DD|null",
          "descricao": "string"
        }
      ],

      "marketing": [
        {
          "dt_referencia": "YYYY-MM-DD",
          "finalidade": "VENDA|LOCACAO",
          "qtd_imobiliarias": "number",
          "visualizacoes": "number",
          "visitas": "number",
          "propostas": "number",
          "propostas_aceitas": "number",
          "status_negociacao": "string"
        }
      ]
    }
  ]
}
````

## 4. Mapeamento para HTML

* `resumo.*` → cards da seção “Síntese dos Investimentos Imobiliários”.
* `imoveis[*]` → tabela “Composição Imobiliária”.
* `imoveis[*].due_diligence` → tabela “Due Diligence”.
* `imoveis[*].marketing` → tabela “Movimentação Comercial”.

## 5. Mapeamento para outros frontends

### 5.1. React / Vue

* O mesmo JSON acima pode ser carregado via API REST.
* O componente de filtro deve operar sobre `filtros_aplicados` e reenviar a query para o backend.
* Tabelas podem consumir diretamente `imoveis` e suas coleções internas.

### 5.2. Appsmith / Low-Code

* Configurar datasource REST apontando para `/report/imoveis` (JSON).
* Vincular tabelas diretamente em `data.imoveis`.
* Cards de KPI alimentados por `data.resumo`.

## 6. Compatibilidade Retroativa

* Versões `1.x` devem preservar campos obrigatórios de `1.0.0`.
* Campos novos devem ser opcionais no contrato.

````

---

## 21. `README.md`

```md
# Real Estate Reporting – HTML + PDF

Pipeline de geração de **relatório imobiliário** dinâmico em HTML,
com exportação para PDF a partir de templates Jinja2 e banco de dados padronizado.

## Stack

- Python / FastAPI
- Jinja2 (templates HTML)
- WeasyPrint (HTML → PDF)
- SQLAlchemy (modelo relacional de imóveis)
- Configuração 100% via `.env`

## Estrutura

Ver diretórios principais:

- `backend/app` – API, serviços e modelos
- `templates` – templates HTML (base + relatório)
- `static` – CSS e JS
- `scripts` – inicialização da base e geração de PDF via CLI
- `docs/MASTER_TEMPLATE_SPEC.md` – contrato de dados e versionamento do template

## Setup

1. Criar e ativar virtualenv (opcional):

```bash
python -m venv .venv
source .venv/bin/activate  # Linux / macOS
# ou .venv\Scripts\activate no Windows
````

2. Instalar dependências:

```bash
pip install -r requirements.txt
```

3. Configurar `.env`:

```bash
cp .env.example .env
# editar REPORT_DATABASE_URL, REPORT_PDF_OUTPUT_DIR etc.
```

4. Inicializar banco (schema já é criado no startup da API, este script faz o seed):

```bash
python scripts/init_db.py
```

5. Subir API:

```bash
uvicorn backend.app.main:app --reload
```

* HTML: `http://localhost:8000/report/imoveis`
* PDF: `http://localhost:8000/report/imoveis/pdf?...`

## Geração de PDF via CLI

```bash
python scripts/generate_pdf_cli.py
```

O arquivo é salvo em `REPORT_PDF_OUTPUT_DIR` (configurado em `.env`).

## Extensões

* Adicionar novas versões de template → atualizar `REPORT_TEMPLATE_VERSION`
  e documentar em `docs/MASTER_TEMPLATE_SPEC.md`.
* Frontends alternativos (React, Vue, Appsmith, Dify) devem consumir o
  **mesmo contrato de dados** definido no documento mestre.

```

---

Se quiser, no próximo passo posso adaptar isso para um **Dockerfile + docker-compose** ou para um **deployment em GCP (Cloud Run / GCE)** já plugando Postgres gerenciado e NocoDB como front de dados.
```
