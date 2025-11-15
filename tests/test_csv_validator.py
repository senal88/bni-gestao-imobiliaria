"""
Tests for CSV validator
"""

import pytest
import tempfile
from pathlib import Path
from src.validators.csv_validator import PropertySchemaValidator, validate_csv


@pytest.fixture
def valid_csv():
    """Create a valid CSV file for testing"""
    content = """id_propriedade,nome,tipo,endereco,cidade,estado,cep,area_m2,valor_aquisicao,data_aquisicao,valor_atual,renda_mensal,inquilino,status
PROP001,Test Property,Comercial,Rua Test 123,São Paulo,SP,01234-567,100.00,100000.00,2020-01-01,150000.00,1000.00,Test Tenant,Ocupada
"""
    with tempfile.NamedTemporaryFile(mode='w', suffix='.csv', delete=False, encoding='utf-8') as f:
        f.write(content)
        return Path(f.name)


@pytest.fixture
def invalid_csv():
    """Create an invalid CSV file for testing"""
    content = """id_propriedade,nome,tipo,endereco,cidade,estado,cep,area_m2,valor_aquisicao,data_aquisicao,valor_atual,renda_mensal,inquilino,status
INVALID,Test Property,InvalidType,Rua Test 123,São Paulo,XX,invalid-cep,-100.00,100000.00,invalid-date,150000.00,1000.00,Test Tenant,InvalidStatus
"""
    with tempfile.NamedTemporaryFile(mode='w', suffix='.csv', delete=False, encoding='utf-8') as f:
        f.write(content)
        return Path(f.name)


def test_valid_csv(valid_csv):
    """Test validation of a valid CSV file"""
    validator = PropertySchemaValidator()
    assert validator.validate_file(valid_csv) is True
    assert len(validator.get_errors()) == 0


def test_invalid_csv(invalid_csv):
    """Test validation of an invalid CSV file"""
    validator = PropertySchemaValidator()
    assert validator.validate_file(invalid_csv) is False
    assert len(validator.get_errors()) > 0


def test_missing_file():
    """Test validation of a non-existent file"""
    validator = PropertySchemaValidator()
    assert validator.validate_file(Path("nonexistent.csv")) is False
    errors = validator.get_errors()
    assert len(errors) > 0
    assert errors[0]["type"] == "file_error"


def test_schema_definition():
    """Test that schema has required fields"""
    validator = PropertySchemaValidator()
    schema = validator.PROPERTY_SCHEMA
    
    required_fields = [
        "id_propriedade", "nome", "tipo", "endereco", "cidade",
        "estado", "cep", "area_m2", "valor_aquisicao", 
        "data_aquisicao", "valor_atual", "status"
    ]
    
    for field in required_fields:
        assert field in schema
        assert schema[field].get("required") is True


def test_validate_row_with_invalid_tipo():
    """Test row validation with invalid tipo"""
    validator = PropertySchemaValidator()
    row = {
        "id_propriedade": "PROP001",
        "nome": "Test",
        "tipo": "InvalidType",
        "endereco": "Test",
        "cidade": "Test",
        "estado": "SP",
        "cep": "12345-678",
        "area_m2": "100",
        "valor_aquisicao": "100000",
        "data_aquisicao": "2020-01-01",
        "valor_atual": "150000",
        "status": "Ocupada"
    }
    
    validator._validate_row(row, 2)
    errors = validator.get_errors()
    
    assert len(errors) > 0
    assert any("tipo" in error.get("field", "") for error in errors)


def test_validate_row_with_negative_area():
    """Test row validation with negative area"""
    validator = PropertySchemaValidator()
    row = {
        "id_propriedade": "PROP001",
        "nome": "Test",
        "tipo": "Comercial",
        "endereco": "Test",
        "cidade": "Test",
        "estado": "SP",
        "cep": "12345-678",
        "area_m2": "-100",
        "valor_aquisicao": "100000",
        "data_aquisicao": "2020-01-01",
        "valor_atual": "150000",
        "status": "Ocupada"
    }
    
    validator._validate_row(row, 2)
    errors = validator.get_errors()
    
    assert len(errors) > 0
    assert any("area_m2" in error.get("field", "") for error in errors)
