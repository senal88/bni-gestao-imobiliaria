#!/usr/bin/env python3
"""
Script de validação de schemas CSV.
Valida arquivos CSV contra schemas JSON definidos.
"""

import os
import sys
import argparse
import json
from pathlib import Path
from dotenv import load_dotenv
import pandas as pd
import jsonschema
from jsonschema import validate, ValidationError

# Adiciona o diretório raiz ao path
sys.path.insert(0, str(Path(__file__).parent.parent))

load_dotenv()


def load_schema(schema_path):
    """Carrega um schema JSON."""
    try:
        with open(schema_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"❌ Erro ao carregar schema {schema_path}: {e}")
        return None


def validate_csv_against_schema(csv_path, schema):
    """Valida um arquivo CSV contra um schema."""
    errors = []
    warnings = []

    try:
        # Carrega CSV
        df = pd.read_csv(csv_path)

        # Valida estrutura básica
        required_fields = schema.get('required', [])
        for field in required_fields:
            if field not in df.columns:
                errors.append(f"Campo obrigatório '{field}' não encontrado")

        # Valida tipos de dados
        properties = schema.get('properties', {})
        for column in df.columns:
            if column in properties:
                expected_type = properties[column].get('type')
                if expected_type:
                    # Verifica tipo (simplificado)
                    if expected_type == 'number' and not pd.api.types.is_numeric_dtype(df[column]):
                        warnings.append(f"Coluna '{column}' deveria ser numérica")
                    elif expected_type == 'string' and pd.api.types.is_numeric_dtype(df[column]):
                        warnings.append(f"Coluna '{column}' deveria ser texto")

        # Valida valores nulos em campos obrigatórios
        for field in required_fields:
            if field in df.columns and df[field].isna().any():
                null_count = df[field].isna().sum()
                errors.append(f"Campo obrigatório '{field}' tem {null_count} valor(es) nulo(s)")

        # Valida formato específico se definido
        for column in df.columns:
            if column in properties:
                format_type = properties[column].get('format')
                if format_type == 'date':
                    # Tenta converter para data
                    try:
                        pd.to_datetime(df[column], errors='raise')
                    except:
                        errors.append(f"Coluna '{column}' contém valores de data inválidos")

        return {
            'valid': len(errors) == 0,
            'errors': errors,
            'warnings': warnings,
            'row_count': len(df),
            'column_count': len(df.columns)
        }

    except Exception as e:
        return {
            'valid': False,
            'errors': [f"Erro ao processar arquivo: {e}"],
            'warnings': [],
            'row_count': 0,
            'column_count': 0
        }


def find_schema_for_csv(csv_path, schemas_dir):
    """Encontra o schema correspondente para um CSV."""
    csv_name = csv_path.stem
    schema_path = Path(schemas_dir) / f"{csv_name}_schema.json"

    if schema_path.exists():
        return schema_path

    # Tenta schema genérico
    generic_schema = Path(schemas_dir) / "default_schema.json"
    if generic_schema.exists():
        return generic_schema

    return None


def validate_all_csvs(data_dir, schemas_dir):
    """Valida todos os CSVs em um diretório."""
    data_path = Path(data_dir)
    schemas_path = Path(schemas_dir)

    if not data_path.exists():
        print(f"❌ Diretório de dados não encontrado: {data_path}")
        return False

    if not schemas_path.exists():
        print(f"❌ Diretório de schemas não encontrado: {schemas_path}")
        return False

    csv_files = list(data_path.glob("*.csv"))

    if not csv_files:
        print(f"⚠️  Nenhum arquivo CSV encontrado em {data_path}")
        return True

    print(f"📊 Validando {len(csv_files)} arquivo(s) CSV...")
    print("-" * 50)

    all_valid = True

    for csv_file in csv_files:
        print(f"\n📄 {csv_file.name}")

        schema_path = find_schema_for_csv(csv_file, schemas_path)

        if not schema_path:
            print(f"  ⚠️  Schema não encontrado para {csv_file.name}")
            continue

        schema = load_schema(schema_path)
        if not schema:
            all_valid = False
            continue

        result = validate_csv_against_schema(csv_file, schema)

        if result['valid']:
            print(f"  ✅ Válido ({result['row_count']} linhas, {result['column_count']} colunas)")
            if result['warnings']:
                for warning in result['warnings']:
                    print(f"    ⚠️  {warning}")
        else:
            print(f"  ❌ Inválido")
            for error in result['errors']:
                print(f"    • {error}")
            all_valid = False

    print("-" * 50)
    return all_valid


def main():
    parser = argparse.ArgumentParser(description='Valida schemas CSV')
    parser.add_argument('--data-dir', type=str,
                       default=os.getenv('DATA_RAW_PATH', './data/raw'),
                       help='Diretório com arquivos CSV para validar')
    parser.add_argument('--schemas-dir', type=str,
                       default=os.getenv('DATA_SCHEMAS_PATH', './data/schemas'),
                       help='Diretório com schemas JSON')
    parser.add_argument('--verbose', '-v', action='store_true',
                       help='Mostra informações detalhadas')

    args = parser.parse_args()

    print("🔍 Validação de Schemas CSV")
    print("-" * 50)

    success = validate_all_csvs(args.data_dir, args.schemas_dir)

    if success:
        print("\n✅ Todas as validações passaram!")
        sys.exit(0)
    else:
        print("\n❌ Algumas validações falharam!")
        sys.exit(1)


if __name__ == '__main__':
    main()

