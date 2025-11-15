"""
Tests for API endpoints
"""

import pytest
from fastapi.testclient import TestClient
from src.api.main import app, properties_data, Property


@pytest.fixture
def client():
    """Create a test client"""
    return TestClient(app)


@pytest.fixture(autouse=True)
def sample_properties():
    """Load sample properties into the global data store"""
    import src.api.main as api_main
    api_main.properties_data = [
        Property(
            id_propriedade="PROP001",
            nome="Test Property 1",
            tipo="Comercial",
            endereco="Rua Test 123",
            cidade="São Paulo",
            estado="SP",
            cep="01234-567",
            area_m2=100.0,
            valor_aquisicao=100000.0,
            data_aquisicao="2020-01-01",
            valor_atual=150000.0,
            renda_mensal=1000.0,
            inquilino="Test Tenant",
            status="Ocupada"
        ),
        Property(
            id_propriedade="PROP002",
            nome="Test Property 2",
            tipo="Residencial",
            endereco="Av Test 456",
            cidade="Rio de Janeiro",
            estado="RJ",
            cep="20000-000",
            area_m2=80.0,
            valor_aquisicao=200000.0,
            data_aquisicao="2021-01-01",
            valor_atual=250000.0,
            renda_mensal=2000.0,
            inquilino="",
            status="Vaga"
        )
    ]
    yield
    api_main.properties_data = []


def test_root_endpoint(client):
    """Test root endpoint"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert "version" in data


def test_health_check(client):
    """Test health check endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "timestamp" in data


def test_get_all_properties(client, sample_properties):
    """Test getting all properties"""
    response = client.get("/properties")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    assert data[0]["id_propriedade"] == "PROP001"


def test_get_property_by_id(client, sample_properties):
    """Test getting a specific property"""
    response = client.get("/properties/PROP001")
    assert response.status_code == 200
    data = response.json()
    assert data["id_propriedade"] == "PROP001"
    assert data["nome"] == "Test Property 1"


def test_get_nonexistent_property(client, sample_properties):
    """Test getting a property that doesn't exist"""
    response = client.get("/properties/PROP999")
    assert response.status_code == 404


def test_filter_properties_by_tipo(client, sample_properties):
    """Test filtering properties by tipo"""
    response = client.get("/properties?tipo=Comercial")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["tipo"] == "Comercial"


def test_filter_properties_by_estado(client, sample_properties):
    """Test filtering properties by estado"""
    response = client.get("/properties?estado=RJ")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["estado"] == "RJ"


def test_filter_properties_by_status(client, sample_properties):
    """Test filtering properties by status"""
    response = client.get("/properties?status=Vaga")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["status"] == "Vaga"


def test_filter_properties_by_value_range(client, sample_properties):
    """Test filtering properties by value range"""
    response = client.get("/properties?min_valor=150000&max_valor=200000")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["valor_atual"] == 150000.0


def test_get_portfolio_stats(client, sample_properties):
    """Test getting portfolio statistics"""
    response = client.get("/stats")
    assert response.status_code == 200
    data = response.json()
    
    assert data["total_properties"] == 2
    assert data["total_value"] == 400000.0  # 150000 + 250000
    assert data["total_monthly_income"] == 3000.0  # 1000 + 2000
    assert data["occupied_count"] == 1
    assert data["vacant_count"] == 1
    assert "types_distribution" in data
    assert "states_distribution" in data
