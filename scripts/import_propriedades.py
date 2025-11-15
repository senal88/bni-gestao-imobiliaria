#!/usr/bin/env python3
"""
Script para importar dados de propriedades do CSV para PostgreSQL.
Processa o arquivo CSV e insere/atualiza dados no banco de dados.
"""

import os
import sys
import argparse
from pathlib import Path
from datetime import datetime
from dotenv import load_dotenv
import pandas as pd
import psycopg2
from psycopg2.extras import execute_values, Json
from psycopg2 import sql

# Adiciona o diretório raiz ao path
sys.path.insert(0, str(Path(__file__).parent.parent))

load_dotenv()


def get_db_connection():
    """Cria conexão com o banco de dados."""
    try:
        conn = psycopg2.connect(
            host=os.getenv('POSTGRES_HOST', 'localhost'),
            port=os.getenv('POSTGRES_PORT', '5432'),
            database=os.getenv('POSTGRES_DB', 'bni_gestao'),
            user=os.getenv('POSTGRES_USER', 'postgres'),
            password=os.getenv('POSTGRES_PASSWORD', 'postgres')
        )
        return conn
    except psycopg2.Error as e:
        print(f"❌ Erro ao conectar ao banco de dados: {e}")
        sys.exit(1)


def normalize_value(value):
    """Normaliza valores N/A e strings numéricas."""
    if pd.isna(value) or value == 'N/A' or value == '':
        return None
    if isinstance(value, str):
        # Remove espaços e tenta converter
        value = value.strip()
        if value == 'N/A' or value == '':
            return None
        try:
            return float(value.replace(',', '.'))
        except ValueError:
            return value
    return value


def normalize_date(value):
    """Normaliza datas."""
    if pd.isna(value) or value == 'N/A' or value == '':
        return None
    if isinstance(value, str):
        value = value.strip()
        if value == 'N/A' or value == '':
            return None
    return value


def prepare_data(df):
    """Prepara dados do DataFrame para inserção no banco."""
    records = []

    for _, row in df.iterrows():
        valor_2023 = normalize_value(row.get('VALOR_31_12_2023_R$'))
        valor_2024 = normalize_value(row.get('VALOR_31_12_2024_R$'))
        preco_promessa = normalize_value(row.get('PRECO_TOTAL_PROMESSA_R$'))
        data_habite_se = normalize_date(row.get('DATA_HABITE_SE_PREVISTA'))

        # Converte data se não for None
        if data_habite_se and data_habite_se != 'N/A':
            try:
                data_habite_se = datetime.strptime(data_habite_se, '%Y-%m-%d').date()
            except:
                data_habite_se = None
        else:
            data_habite_se = None

        record = {
            'codigo': str(row['CODIGO_CC']),
            'codigo_cc': str(row['CODIGO_CC']),
            'nome': str(row['NOME_IMOVEL']),
            'tipo_propriedade': None,  # Pode ser inferido do nome depois
            'tipo_estoque': str(row.get('TIPO_ESTOQUE', 'N/D')),
            'valor_avaliacao': valor_2024 or valor_2023,
            'valor_2023': valor_2023,
            'valor_2024': valor_2024,
            'preco_promessa': preco_promessa,
            'status': str(row.get('STATUS_ATUAL', 'Concluído')),
            'data_habite_se_prevista': data_habite_se,
            'observacoes': str(row.get('OBSERVACOES_FINANCEIRAS', '')),
            'metadata': {
                'id': int(row['ID']),
                'codigo_cc': str(row['CODIGO_CC']),
                'valor_2023': valor_2023,
                'valor_2024': valor_2024,
                'preco_promessa': preco_promessa,
                'data_habite_se': str(data_habite_se) if data_habite_se else None,
                'tipo_estoque': str(row.get('TIPO_ESTOQUE', 'N/D'))
            }
        }
        records.append(record)

    return records


def import_propriedades(csv_path, dry_run=False):
    """Importa propriedades do CSV para o banco de dados."""
    print(f"📊 Importando propriedades de {csv_path}")
    print("-" * 50)

    # Carrega CSV
    try:
        df = pd.read_csv(csv_path)
        print(f"✅ CSV carregado: {len(df)} registros")
    except Exception as e:
        print(f"❌ Erro ao carregar CSV: {e}")
        sys.exit(1)

    # Prepara dados
    records = prepare_data(df)
    print(f"✅ Dados preparados: {len(records)} registros")

    if dry_run:
        print("\n🔍 DRY RUN - Dados que seriam inseridos:")
        for i, record in enumerate(records[:5], 1):
            print(f"\n{i}. {record['nome']}")
            print(f"   Código: {record['codigo']}")
            print(f"   Valor: R$ {record['valor_avaliacao']:,.2f}" if record['valor_avaliacao'] else "   Valor: N/A")
            print(f"   Status: {record['status']}")
        if len(records) > 5:
            print(f"\n... e mais {len(records) - 5} registros")
        return

    # Conecta ao banco
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Insere ou atualiza propriedades
        inserted = 0
        updated = 0

        for record in records:
            # Verifica se já existe
            cursor.execute(
                "SELECT id FROM propriedades WHERE codigo = %s",
                (record['codigo'],)
            )
            existing = cursor.fetchone()

            if existing:
                # Atualiza
                cursor.execute("""
                    UPDATE propriedades
                    SET codigo_cc = %s,
                        nome = %s,
                        tipo_estoque = %s,
                        valor_avaliacao = %s,
                        valor_2023 = %s,
                        valor_2024 = %s,
                        preco_promessa = %s,
                        status = %s,
                        data_habite_se_prevista = %s,
                        observacoes = %s,
                        metadata = %s,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE codigo = %s
                """, (
                    record['codigo_cc'],
                    record['nome'],
                    record['tipo_estoque'],
                    record['valor_avaliacao'],
                    record['valor_2023'],
                    record['valor_2024'],
                    record['preco_promessa'],
                    record['status'],
                    record['data_habite_se_prevista'],
                    record['observacoes'],
                    Json(record['metadata']),
                    record['codigo']
                ))
                updated += 1
            else:
                # Insere
                cursor.execute("""
                    INSERT INTO propriedades (
                        codigo, codigo_cc, nome, tipo_estoque,
                        valor_avaliacao, valor_2023, valor_2024,
                        preco_promessa, status, data_habite_se_prevista,
                        observacoes, metadata
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """, (
                    record['codigo'],
                    record['codigo_cc'],
                    record['nome'],
                    record['tipo_estoque'],
                    record['valor_avaliacao'],
                    record['valor_2023'],
                    record['valor_2024'],
                    record['preco_promessa'],
                    record['status'],
                    record['data_habite_se_prevista'],
                    record['observacoes'],
                    psycopg2.extras.Json(record['metadata'])
                ))
                inserted += 1

        conn.commit()

        print(f"\n✅ Importação concluída!")
        print(f"   Inseridos: {inserted}")
        print(f"   Atualizados: {updated}")
        print(f"   Total processado: {len(records)}")

    except Exception as e:
        conn.rollback()
        print(f"❌ Erro durante importação: {e}")
        sys.exit(1)
    finally:
        cursor.close()
        conn.close()


def main():
    parser = argparse.ArgumentParser(description='Importa propriedades do CSV para PostgreSQL')
    parser.add_argument('--csv', type=str,
                       default=os.getenv('DATA_RAW_PATH', './data/raw') + '/propriedades.csv',
                       help='Caminho do arquivo CSV')
    parser.add_argument('--dry-run', action='store_true',
                       help='Apenas mostra o que seria importado, sem inserir no banco')

    args = parser.parse_args()

    csv_path = Path(args.csv)

    if not csv_path.exists():
        print(f"❌ Arquivo CSV não encontrado: {csv_path}")
        sys.exit(1)

    import_propriedades(csv_path, dry_run=args.dry_run)


if __name__ == '__main__':
    main()

