#!/usr/bin/env python3
"""
Script de inicialização do banco de dados PostgreSQL.
Cria as tabelas e estruturas necessárias para o sistema de gestão imobiliária.
"""

import os
import sys
import argparse
from pathlib import Path
from dotenv import load_dotenv
import psycopg2
from psycopg2 import sql
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

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


def create_database_if_not_exists():
    """Cria o banco de dados se não existir."""
    db_name = os.getenv('POSTGRES_DB', 'bni_gestao')

    # Conecta ao postgres padrão para criar o banco
    try:
        conn = psycopg2.connect(
            host=os.getenv('POSTGRES_HOST', 'localhost'),
            port=os.getenv('POSTGRES_PORT', '5432'),
            database='postgres',
            user=os.getenv('POSTGRES_USER', 'postgres'),
            password=os.getenv('POSTGRES_PASSWORD', 'postgres')
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()

        # Verifica se o banco existe
        cursor.execute(
            "SELECT 1 FROM pg_database WHERE datname = %s",
            (db_name,)
        )

        if not cursor.fetchone():
            cursor.execute(sql.SQL("CREATE DATABASE {}").format(
                sql.Identifier(db_name)
            ))
            print(f"✅ Banco de dados '{db_name}' criado com sucesso!")
        else:
            print(f"ℹ️  Banco de dados '{db_name}' já existe.")

        cursor.close()
        conn.close()
    except psycopg2.Error as e:
        print(f"⚠️  Aviso: Não foi possível criar o banco de dados: {e}")


def create_tables(conn):
    """Cria as tabelas do sistema."""
    cursor = conn.cursor()

    # Tabela de propriedades
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS propriedades (
            id SERIAL PRIMARY KEY,
            codigo VARCHAR(50) UNIQUE NOT NULL,
            nome VARCHAR(255) NOT NULL,
            endereco TEXT,
            cidade VARCHAR(100),
            estado VARCHAR(2),
            cep VARCHAR(10),
            tipo_propriedade VARCHAR(50),
            area_total DECIMAL(10, 2),
            area_construida DECIMAL(10, 2),
            valor_avaliacao DECIMAL(12, 2),
            status VARCHAR(50),
            data_aquisicao DATE,
            observacoes TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    """)

    # Tabela de transações
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS transacoes (
            id SERIAL PRIMARY KEY,
            propriedade_id INTEGER REFERENCES propriedades(id),
            tipo_transacao VARCHAR(50) NOT NULL,
            valor DECIMAL(12, 2) NOT NULL,
            data_transacao DATE NOT NULL,
            descricao TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    """)

    # Tabela de relatórios IFRS
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS relatorios_ifrs (
            id SERIAL PRIMARY KEY,
            periodo VARCHAR(20) NOT NULL,
            tipo_relatorio VARCHAR(100) NOT NULL,
            arquivo_path VARCHAR(500),
            data_geracao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            status VARCHAR(50) DEFAULT 'pendente'
        );
    """)

    # Índices
    cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_propriedades_codigo ON propriedades(codigo);
        CREATE INDEX IF NOT EXISTS idx_propriedades_status ON propriedades(status);
        CREATE INDEX IF NOT EXISTS idx_transacoes_propriedade ON transacoes(propriedade_id);
        CREATE INDEX IF NOT EXISTS idx_transacoes_data ON transacoes(data_transacao);
    """)

    conn.commit()
    cursor.close()
    print("✅ Tabelas criadas com sucesso!")


def validate_connection(conn):
    """Valida a conexão com o banco de dados."""
    cursor = conn.cursor()
    cursor.execute("SELECT version();")
    version = cursor.fetchone()
    cursor.close()
    print(f"✅ Conexão validada! PostgreSQL {version[0]}")
    return True


def main():
    parser = argparse.ArgumentParser(description='Inicializa o banco de dados PostgreSQL')
    parser.add_argument('--validate-only', action='store_true',
                       help='Apenas valida a conexão sem criar tabelas')
    args = parser.parse_args()

    print("🚀 Inicializando banco de dados PostgreSQL...")
    print("-" * 50)

    # Tenta criar o banco se não existir
    if not args.validate_only:
        create_database_if_not_exists()

    # Conecta ao banco
    conn = get_db_connection()

    # Valida conexão
    validate_connection(conn)

    if args.validate_only:
        print("✅ Validação concluída!")
        conn.close()
        return

    # Cria tabelas
    create_tables(conn)

    conn.close()
    print("-" * 50)
    print("✅ Inicialização concluída com sucesso!")


if __name__ == '__main__':
    main()

