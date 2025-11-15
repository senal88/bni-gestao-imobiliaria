"""
CSV Schema Validator for BNI Real Estate Portfolio
Validates property data against defined schema
"""

import csv
import json
from typing import Dict, List, Any, Optional
from pathlib import Path
import logging

logger = logging.getLogger(__name__)


class PropertySchemaValidator:
    """Validates CSV files against property schema"""
    
    # Schema definition for property data
    PROPERTY_SCHEMA = {
        "id_propriedade": {"type": "str", "required": True, "pattern": r"^PROP\d{3}$"},
        "nome": {"type": "str", "required": True, "min_length": 1},
        "tipo": {"type": "str", "required": True, "enum": ["Residencial", "Comercial", "Industrial", "Terreno"]},
        "endereco": {"type": "str", "required": True},
        "cidade": {"type": "str", "required": True},
        "estado": {"type": "str", "required": True, "min_length": 2, "max_length": 2},
        "cep": {"type": "str", "required": True, "pattern": r"^\d{5}-\d{3}$"},
        "area_m2": {"type": "float", "required": True, "min": 0},
        "valor_aquisicao": {"type": "float", "required": True, "min": 0},
        "data_aquisicao": {"type": "str", "required": True, "pattern": r"^\d{4}-\d{2}-\d{2}$"},
        "valor_atual": {"type": "float", "required": True, "min": 0},
        "renda_mensal": {"type": "float", "required": False, "min": 0, "default": 0.0},
        "inquilino": {"type": "str", "required": False, "default": ""},
        "status": {"type": "str", "required": True, "enum": ["Ocupada", "Vaga", "Em Reforma", "À Venda"]},
    }
    
    def __init__(self):
        self.errors: List[Dict[str, Any]] = []
    
    def validate_file(self, filepath: Path) -> bool:
        """
        Validate a CSV file against the property schema
        
        Args:
            filepath: Path to CSV file
            
        Returns:
            True if valid, False otherwise
        """
        self.errors = []
        
        if not filepath.exists():
            self.errors.append({
                "type": "file_error",
                "message": f"File not found: {filepath}"
            })
            return False
        
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                headers = reader.fieldnames
                
                # Check if all required columns are present
                if not self._validate_headers(headers):
                    return False
                
                # Validate each row
                for row_num, row in enumerate(reader, start=2):  # Start at 2 (header is row 1)
                    self._validate_row(row, row_num)
                
        except Exception as e:
            self.errors.append({
                "type": "file_error",
                "message": f"Error reading file: {str(e)}"
            })
            return False
        
        return len(self.errors) == 0
    
    def _validate_headers(self, headers: List[str]) -> bool:
        """Validate CSV headers against schema"""
        required_fields = [k for k, v in self.PROPERTY_SCHEMA.items() if v.get("required")]
        missing_fields = set(required_fields) - set(headers)
        
        if missing_fields:
            self.errors.append({
                "type": "header_error",
                "message": f"Missing required columns: {', '.join(missing_fields)}"
            })
            return False
        
        return True
    
    def _validate_row(self, row: Dict[str, str], row_num: int):
        """Validate a single row against schema"""
        for field, rules in self.PROPERTY_SCHEMA.items():
            value = row.get(field, "").strip()
            
            # Check required fields
            if rules.get("required") and not value:
                self.errors.append({
                    "type": "validation_error",
                    "row": row_num,
                    "field": field,
                    "message": f"Required field '{field}' is empty"
                })
                continue
            
            # Skip validation for empty optional fields
            if not value and not rules.get("required"):
                continue
            
            # Type validation
            field_type = rules.get("type")
            if field_type == "float":
                try:
                    float_value = float(value)
                    if "min" in rules and float_value < rules["min"]:
                        self.errors.append({
                            "type": "validation_error",
                            "row": row_num,
                            "field": field,
                            "message": f"Value {float_value} is less than minimum {rules['min']}"
                        })
                except ValueError:
                    self.errors.append({
                        "type": "validation_error",
                        "row": row_num,
                        "field": field,
                        "message": f"Invalid float value: {value}"
                    })
            
            # Enum validation
            if "enum" in rules and value not in rules["enum"]:
                self.errors.append({
                    "type": "validation_error",
                    "row": row_num,
                    "field": field,
                    "message": f"Value '{value}' not in allowed values: {rules['enum']}"
                })
            
            # Pattern validation
            if "pattern" in rules:
                import re
                if not re.match(rules["pattern"], value):
                    self.errors.append({
                        "type": "validation_error",
                        "row": row_num,
                        "field": field,
                        "message": f"Value '{value}' does not match pattern {rules['pattern']}"
                    })
            
            # Length validation
            if "min_length" in rules and len(value) < rules["min_length"]:
                self.errors.append({
                    "type": "validation_error",
                    "row": row_num,
                    "field": field,
                    "message": f"Value length {len(value)} is less than minimum {rules['min_length']}"
                })
            
            if "max_length" in rules and len(value) > rules["max_length"]:
                self.errors.append({
                    "type": "validation_error",
                    "row": row_num,
                    "field": field,
                    "message": f"Value length {len(value)} exceeds maximum {rules['max_length']}"
                })
    
    def get_errors(self) -> List[Dict[str, Any]]:
        """Get list of validation errors"""
        return self.errors
    
    def print_errors(self):
        """Print validation errors in a readable format"""
        if not self.errors:
            print("✓ Validation passed: No errors found")
            return
        
        print(f"✗ Validation failed: {len(self.errors)} error(s) found\n")
        for error in self.errors:
            if error["type"] == "header_error":
                print(f"[HEADER] {error['message']}")
            elif error["type"] == "file_error":
                print(f"[FILE] {error['message']}")
            else:
                print(f"[Row {error['row']}] {error['field']}: {error['message']}")


def validate_csv(filepath: str) -> bool:
    """
    Convenience function to validate a CSV file
    
    Args:
        filepath: Path to CSV file
        
    Returns:
        True if valid, False otherwise
    """
    validator = PropertySchemaValidator()
    is_valid = validator.validate_file(Path(filepath))
    validator.print_errors()
    return is_valid


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python csv_validator.py <csv_file>")
        sys.exit(1)
    
    filepath = sys.argv[1]
    is_valid = validate_csv(filepath)
    sys.exit(0 if is_valid else 1)
