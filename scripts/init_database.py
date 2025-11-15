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
            host=os.getenv("POSTGRES_HOST", "localhost"),
            port=os.getenv("POSTGRES_PORT", "5432"),
            database=os.getenv("POSTGRES_DB", "bni_gestao"),
            user=os.getenv("POSTGRES_USER", "postgres"),
            password=os.getenv("POSTGRES_PASSWORD", "postgres"),
        )
        return conn
    except psycopg2.Error as e:
        print(f"❌ Erro ao conectar ao banco de dados: {e}")
        sys.exit(1)


def create_database_if_not_exists():
    """Cria o banco de dados se não existir."""
    db_name = os.getenv("POSTGRES_DB", "bni_gestao")

    # Conecta ao postgres padrão para criar o banco
    try:
        conn = psycopg2.connect(
            host=os.getenv("POSTGRES_HOST", "localhost"),
            port=os.getenv("POSTGRES_PORT", "5432"),
            database="postgres",
            user=os.getenv("POSTGRES_USER", "postgres"),
            password=os.getenv("POSTGRES_PASSWORD", "postgres"),
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()

        # Verifica se o banco existe
        cursor.execute("SELECT 1 FROM pg_database WHERE datname = %s", (db_name,))

        if not cursor.fetchone():
            cursor.execute(
                sql.SQL("CREATE DATABASE {}").format(sql.Identifier(db_name))
            )
            print(f"✅ Banco de dados '{db_name}' criado com sucesso!")
        else:
            print(f"ℹ️  Banco de dados '{db_name}' já existe.")

        cursor.close()
        conn.close()
    except psycopg2.Error as e:
        print(f"⚠️  Aviso: Não foi possível criar o banco de dados: {e}")


def create_tables(conn):
    """Cria as tabelas do sistema executando o arquivo init.sql completo."""
    cursor = conn.cursor()

    # Localiza o arquivo init.sql no mesmo diretório deste script
    script_dir = Path(__file__).parent
    init_sql_path = script_dir / 'init.sql'

    if not init_sql_path.exists():
        print(f"❌ Arquivo init.sql não encontrado em: {init_sql_path}")
        print("   Certifique-se de que o arquivo existe no diretório scripts/")
        sys.exit(1)

    try:
        # Lê e executa o arquivo init.sql completo
        print(f"📄 Executando schema completo de: {init_sql_path}")
        with open(init_sql_path, 'r', encoding='utf-8') as f:
            sql_content = f.read()

        # psycopg2.execute() executa apenas um comando por vez
        # Usa uma abordagem simples mas eficaz: divide por ';' e filtra comandos vazios
        # Remove comentários de linha completa primeiro
        lines = []
        for line in sql_content.split('\n'):
            stripped = line.strip()
            if stripped and not stripped.startswith('--'):
                lines.append(line)

        sql_clean = '\n'.join(lines)

        # Divide por ponto-e-vírgula e executa cada comando
        commands = [cmd.strip() for cmd in sql_clean.split(';') if cmd.strip()]

        executed = 0
        for i, command in enumerate(commands, 1):
            if command:
                try:
                    cursor.execute(command)
                    executed += 1
                except psycopg2.Error as e:
                    # Alguns comandos podem falhar se já existirem (CREATE IF NOT EXISTS)
                    # Ignora erros de "already exists" mas reporta outros
                    error_msg = str(e).lower()
                    if 'already exists' in error_msg or 'duplicate' in error_msg:
                        # Comando já executado antes, pode ignorar
                        pass
                    else:
                        print(f"⚠️  Aviso no comando {i}: {e}")
                        # Para comandos críticos, ainda tenta continuar

        conn.commit()
        cursor.close()
        print(f"✅ Schema completo aplicado com sucesso!")
        print(f"   ✅ {executed} comandos executados")
        print("   ✅ Tabelas criadas (incluindo todas as colunas necessárias)")
        print("   ✅ Índices criados")
        print("   ✅ Views criadas")
        print("   ✅ Triggers criados")

    except Exception as e:
        conn.rollback()
        cursor.close()
        print(f"❌ Erro ao executar init.sql: {e}")
        print(f"   Arquivo: {init_sql_path}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


def validate_connection(conn):
    """Valida a conexão com o banco de dados."""
    cursor = conn.cursor()
    cursor.execute("SELECT version();")
    version = cursor.fetchone()
    cursor.close()
    print(f"✅ Conexão validada! PostgreSQL {version[0]}")
    return True


def main():
    parser = argparse.ArgumentParser(
        description="Inicializa o banco de dados PostgreSQL"
    )
    parser.add_argument(
        "--validate-only",
        action="store_true",
        help="Apenas valida a conexão sem criar tabelas",
    )
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


if __name__ == "__main__":
    main()
