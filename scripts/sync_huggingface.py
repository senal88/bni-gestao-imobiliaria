#!/usr/bin/env python3
"""
Script de sincronização com Hugging Face Dataset.
Faz upload dos dados processados para o dataset público no Hugging Face.
"""

import os
import sys
import argparse
from pathlib import Path
from dotenv import load_dotenv
from huggingface_hub import HfApi, login
from datasets import Dataset, DatasetDict
import pandas as pd
import json

# Adiciona o diretório raiz ao path
sys.path.insert(0, str(Path(__file__).parent.parent))

load_dotenv()


def load_data_from_directory(data_dir):
    """Carrega dados CSV do diretório especificado."""
    data_path = Path(data_dir)
    data_files = {}

    if not data_path.exists():
        print(f"⚠️  Diretório {data_path} não encontrado.")
        return None

    # Procura por arquivos CSV
    csv_files = list(data_path.glob("*.csv"))

    if not csv_files:
        print(f"⚠️  Nenhum arquivo CSV encontrado em {data_path}")
        return None

    print(f"📁 Encontrados {len(csv_files)} arquivo(s) CSV")

    # Carrega cada CSV
    datasets = {}
    for csv_file in csv_files:
        name = csv_file.stem
        try:
            df = pd.read_csv(csv_file)
            datasets[name] = df
            print(f"  ✓ {name}: {len(df)} registros")
        except Exception as e:
            print(f"  ❌ Erro ao carregar {csv_file}: {e}")

    return datasets


def create_dataset_from_data(data_dict):
    """Cria um Dataset do Hugging Face a partir dos dados."""
    if not data_dict:
        return None

    # Se houver apenas um dataset, cria diretamente
    if len(data_dict) == 1:
        name, df = next(iter(data_dict.items()))
        return Dataset.from_pandas(df)

    # Se houver múltiplos, cria um DatasetDict
    dataset_dict = {}
    for name, df in data_dict.items():
        dataset_dict[name] = Dataset.from_pandas(df)

    return DatasetDict(dataset_dict)


def push_to_huggingface(dataset, dataset_name, token, push_mode="auto"):
    """Faz upload do dataset para o Hugging Face."""
    try:
        # Faz login
        if token:
            login(token=token)
            print("✅ Autenticado no Hugging Face")
        else:
            print("⚠️  Token não fornecido, tentando autenticação existente...")

        # Faz push do dataset
        print(f"📤 Fazendo upload para {dataset_name}...")
        dataset.push_to_hub(
            repo_id=dataset_name,
            private=False,
            token=token
        )

        print(f"✅ Dataset enviado com sucesso para {dataset_name}!")
        return True

    except Exception as e:
        print(f"❌ Erro ao fazer upload: {e}")
        return False


def pull_from_huggingface(dataset_name, token, output_dir):
    """Baixa o dataset do Hugging Face."""
    try:
        from datasets import load_dataset

        print(f"📥 Baixando dataset de {dataset_name}...")
        dataset = load_dataset(dataset_name, token=token)

        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)

        # Salva os dados
        if isinstance(dataset, DatasetDict):
            for name, ds in dataset.items():
                df = ds.to_pandas()
                output_file = output_path / f"{name}.csv"
                df.to_csv(output_file, index=False)
                print(f"  ✓ Salvo: {output_file}")
        else:
            df = dataset.to_pandas()
            output_file = output_path / "dataset.csv"
            df.to_csv(output_file, index=False)
            print(f"  ✓ Salvo: {output_file}")

        print("✅ Download concluído!")
        return True

    except Exception as e:
        print(f"❌ Erro ao baixar dataset: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(description='Sincroniza dados com Hugging Face Dataset')
    parser.add_argument('--push', action='store_true',
                       help='Faz upload dos dados para o Hugging Face')
    parser.add_argument('--pull', action='store_true',
                       help='Baixa dados do Hugging Face')
    parser.add_argument('--data-dir', type=str,
                       default=os.getenv('DATA_PROCESSED_PATH', './data/processed'),
                       help='Diretório com dados para upload')
    parser.add_argument('--output-dir', type=str,
                       default=os.getenv('DATA_RAW_PATH', './data/raw'),
                       help='Diretório para salvar dados baixados')

    args = parser.parse_args()

    # Configurações
    hf_token = os.getenv('HF_TOKEN')
    hf_dataset = os.getenv('HF_DATASET_NAME', 'senal88/bni-gestao-imobiliaria')

    print("🔄 Sincronização com Hugging Face Dataset")
    print("-" * 50)
    print(f"Dataset: {hf_dataset}")
    print("-" * 50)

    if args.push:
        # Carrega dados locais
        data_dict = load_data_from_directory(args.data_dir)

        if not data_dict:
            print("❌ Nenhum dado encontrado para upload.")
            sys.exit(1)

        # Cria dataset
        dataset = create_dataset_from_data(data_dict)

        if dataset:
            # Faz upload
            success = push_to_huggingface(dataset, hf_dataset, hf_token)
            sys.exit(0 if success else 1)
        else:
            print("❌ Erro ao criar dataset.")
            sys.exit(1)

    elif args.pull:
        # Baixa dados
        success = pull_from_huggingface(hf_dataset, hf_token, args.output_dir)
        sys.exit(0 if success else 1)

    else:
        print("⚠️  Especifique --push ou --pull")
        parser.print_help()
        sys.exit(1)


if __name__ == '__main__':
    main()

