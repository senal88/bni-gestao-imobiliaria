"""
REST API for BNI Real Estate Portfolio Management
FastAPI application for property data access
"""

from fastapi import FastAPI, HTTPException, Query
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
import pandas as pd
from pathlib import Path
import logging

logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="BNI Real Estate Portfolio API",
    description="API REST para acesso aos dados do portfólio imobiliário BNI",
    version="1.0.0"
)


# Pydantic models for request/response
class Property(BaseModel):
    """Property data model"""
    id_propriedade: str = Field(..., description="ID único da propriedade")
    nome: str = Field(..., description="Nome da propriedade")
    tipo: str = Field(..., description="Tipo: Residencial, Comercial, Industrial, Terreno")
    endereco: str = Field(..., description="Endereço completo")
    cidade: str = Field(..., description="Cidade")
    estado: str = Field(..., description="Estado (sigla)")
    cep: str = Field(..., description="CEP no formato 00000-000")
    area_m2: float = Field(..., description="Área em metros quadrados", gt=0)
    valor_aquisicao: float = Field(..., description="Valor de aquisição", ge=0)
    data_aquisicao: str = Field(..., description="Data de aquisição (YYYY-MM-DD)")
    valor_atual: float = Field(..., description="Valor atual de mercado", ge=0)
    renda_mensal: Optional[float] = Field(0.0, description="Renda mensal de aluguel", ge=0)
    inquilino: Optional[str] = Field("", description="Nome do inquilino atual")
    status: str = Field(..., description="Status: Ocupada, Vaga, Em Reforma, À Venda")
    
    class Config:
        json_schema_extra = {
            "example": {
                "id_propriedade": "PROP001",
                "nome": "Edifício Central",
                "tipo": "Comercial",
                "endereco": "Rua das Flores, 123",
                "cidade": "São Paulo",
                "estado": "SP",
                "cep": "01234-567",
                "area_m2": 250.5,
                "valor_aquisicao": 500000.0,
                "data_aquisicao": "2020-01-15",
                "valor_atual": 650000.0,
                "renda_mensal": 5000.0,
                "inquilino": "Empresa XYZ",
                "status": "Ocupada"
            }
        }


class PortfolioStats(BaseModel):
    """Portfolio statistics model"""
    total_properties: int
    total_value: float
    total_monthly_income: float
    occupied_count: int
    vacant_count: int
    types_distribution: dict
    states_distribution: dict


class PropertyCreate(BaseModel):
    """Model for creating a new property"""
    id_propriedade: str
    nome: str
    tipo: str
    endereco: str
    cidade: str
    estado: str
    cep: str
    area_m2: float
    valor_aquisicao: float
    data_aquisicao: str
    valor_atual: float
    renda_mensal: Optional[float] = 0.0
    inquilino: Optional[str] = ""
    status: str


# In-memory data store (replace with database in production)
properties_data: List[Property] = []
data_file = Path("data/raw/properties.csv")


def load_properties_from_csv():
    """Load properties from CSV file"""
    global properties_data
    if data_file.exists():
        try:
            df = pd.read_csv(data_file)
            # Replace NaN with empty string for optional fields
            df = df.fillna({'inquilino': '', 'renda_mensal': 0.0})
            properties_data = [Property(**row) for _, row in df.iterrows()]
            logger.info(f"Loaded {len(properties_data)} properties from CSV")
        except Exception as e:
            logger.error(f"Error loading CSV: {str(e)}")
            properties_data = []
    else:
        logger.warning(f"CSV file not found: {data_file}")
        properties_data = []


@app.on_event("startup")
async def startup_event():
    """Load data on startup"""
    load_properties_from_csv()


@app.get("/", tags=["Root"])
async def root():
    """API root endpoint"""
    return {
        "message": "BNI Real Estate Portfolio API",
        "version": "1.0.0",
        "endpoints": {
            "properties": "/properties",
            "stats": "/stats",
            "docs": "/docs"
        }
    }


@app.get("/properties", response_model=List[Property], tags=["Properties"])
async def get_properties(
    tipo: Optional[str] = Query(None, description="Filtrar por tipo de propriedade"),
    estado: Optional[str] = Query(None, description="Filtrar por estado"),
    status: Optional[str] = Query(None, description="Filtrar por status"),
    min_valor: Optional[float] = Query(None, description="Valor mínimo"),
    max_valor: Optional[float] = Query(None, description="Valor máximo"),
):
    """
    Get all properties with optional filters
    
    Returns a list of all properties in the portfolio, with optional filtering
    by type, state, status, and value range.
    """
    filtered_properties = properties_data.copy()
    
    if tipo:
        filtered_properties = [p for p in filtered_properties if p.tipo == tipo]
    
    if estado:
        filtered_properties = [p for p in filtered_properties if p.estado == estado]
    
    if status:
        filtered_properties = [p for p in filtered_properties if p.status == status]
    
    if min_valor is not None:
        filtered_properties = [p for p in filtered_properties if p.valor_atual >= min_valor]
    
    if max_valor is not None:
        filtered_properties = [p for p in filtered_properties if p.valor_atual <= max_valor]
    
    return filtered_properties


@app.get("/properties/{property_id}", response_model=Property, tags=["Properties"])
async def get_property(property_id: str):
    """
    Get a specific property by ID
    
    Returns detailed information about a single property.
    """
    for prop in properties_data:
        if prop.id_propriedade == property_id:
            return prop
    
    raise HTTPException(status_code=404, detail=f"Property {property_id} not found")


@app.get("/stats", response_model=PortfolioStats, tags=["Statistics"])
async def get_portfolio_stats():
    """
    Get portfolio statistics
    
    Returns aggregated statistics about the entire portfolio including
    total value, monthly income, and distribution by type and location.
    """
    if not properties_data:
        return PortfolioStats(
            total_properties=0,
            total_value=0.0,
            total_monthly_income=0.0,
            occupied_count=0,
            vacant_count=0,
            types_distribution={},
            states_distribution={}
        )
    
    total_value = sum(p.valor_atual for p in properties_data)
    total_monthly_income = sum(p.renda_mensal or 0.0 for p in properties_data)
    occupied_count = sum(1 for p in properties_data if p.status == "Ocupada")
    vacant_count = sum(1 for p in properties_data if p.status == "Vaga")
    
    # Type distribution
    types_dist = {}
    for prop in properties_data:
        types_dist[prop.tipo] = types_dist.get(prop.tipo, 0) + 1
    
    # State distribution
    states_dist = {}
    for prop in properties_data:
        states_dist[prop.estado] = states_dist.get(prop.estado, 0) + 1
    
    return PortfolioStats(
        total_properties=len(properties_data),
        total_value=total_value,
        total_monthly_income=total_monthly_income,
        occupied_count=occupied_count,
        vacant_count=vacant_count,
        types_distribution=types_dist,
        states_distribution=states_dist
    )


@app.get("/health", tags=["Health"])
async def health_check():
    """
    Health check endpoint
    
    Returns the current health status of the API.
    """
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "properties_loaded": len(properties_data)
    }


if __name__ == "__main__":
    import uvicorn
    
    # Configure logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    # Run the server
    uvicorn.run(app, host="0.0.0.0", port=8000)
