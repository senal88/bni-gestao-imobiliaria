#!/usr/bin/env python3
"""
Script de exportação para Obsidian.
Gera arquivos Markdown no formato Obsidian a partir dos dados do portfólio.
"""

import os
import sys
import argparse
from pathlib import Path
from datetime import datetime
from dotenv import load_dotenv
import pandas as pd
import yaml

# Adiciona o diretório raiz ao path
sys.path.insert(0, str(Path(__file__).parent.parent))

load_dotenv()


def load_property_data(data_dir):
    """Carrega dados das propriedades."""
    data_path = Path(data_dir)
    csv_files = list(data_path.glob("*propriedades*.csv"))

    if not csv_files:
        print("⚠️  Nenhum arquivo de propriedades encontrado")
        return None

    df = pd.read_csv(csv_files[0])
    return df


def create_obsidian_note(property_data, output_dir, template=None):
    """Cria uma nota Obsidian para uma propriedade."""
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    # Nome do arquivo baseado no código ou nome
    code = str(property_data.get('codigo', property_data.get('nome', 'propriedade')))
    safe_filename = "".join(c for c in code if c.isalnum() or c in (' ', '-', '_')).strip()
    safe_filename = safe_filename.replace(' ', '_')
    filename = f"{safe_filename}.md"
    filepath = output_path / filename

    # Frontmatter YAML
    frontmatter = {
        'codigo': property_data.get('codigo', 'N/A'),
        'tipo': property_data.get('tipo_propriedade', 'N/A'),
        'status': property_data.get('status', 'N/A'),
        'data_criacao': datetime.now().strftime('%Y-%m-%d'),
        'tags': ['propriedade', 'bni']
    }

    # Conteúdo Markdown
    content = f"""---
{yaml.dump(frontmatter, default_flow_style=False, allow_unicode=True)}---

# {property_data.get('nome', 'Propriedade sem nome')}

## Informações Básicas

- **Código**: {property_data.get('codigo', 'N/A')}
- **Tipo**: {property_data.get('tipo_propriedade', 'N/A')}
- **Status**: {property_data.get('status', 'N/A')}

## Localização

- **Endereço**: {property_data.get('endereco', 'N/A')}
- **Cidade**: {property_data.get('cidade', 'N/A')}
- **Estado**: {property_data.get('estado', 'N/A')}
- **CEP**: {property_data.get('cep', 'N/A')}

## Características

- **Área Total**: {property_data.get('area_total', 'N/A')} m²
- **Área Construída**: {property_data.get('area_construida', 'N/A')} m²
- **Valor de Avaliação**: R$ {property_data.get('valor_avaliacao', 0):,.2f}

## Histórico

- **Data de Aquisição**: {property_data.get('data_aquisicao', 'N/A')}

## Observações

{property_data.get('observacoes', 'Nenhuma observação registrada.')}

---

*Última atualização: {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}*
"""

    # Salva arquivo
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

    return filepath


def create_index_note(properties_df, output_dir):
    """Cria uma nota índice com todas as propriedades."""
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    index_path = output_path / "00_Índice_Propriedades.md"

    content = f"""# Índice de Propriedades - BNI

*Gerado em: {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}*

## Resumo

- **Total de Propriedades**: {len(properties_df)}
- **Valor Total do Portfólio**: R$ {properties_df['valor_avaliacao'].sum():,.2f if 'valor_avaliacao' in properties_df.columns else 0:,.2f}

## Lista de Propriedades

"""

    # Adiciona links para cada propriedade
    if 'codigo' in properties_df.columns and 'nome' in properties_df.columns:
        for _, prop in properties_df.iterrows():
            code = str(prop.get('codigo', prop.get('nome', 'propriedade')))
            safe_filename = "".join(c for c in code if c.isalnum() or c in (' ', '-', '_')).strip()
            safe_filename = safe_filename.replace(' ', '_')
            link = f"[[{safe_filename}]]"
            name = prop.get('nome', 'Sem nome')
            content += f"- {link} - {name}\n"

    content += f"""
---

## Tags

#propriedade #bni #portfólio #índice
"""

    with open(index_path, 'w', encoding='utf-8') as f:
        f.write(content)

    return index_path


def main():
    parser = argparse.ArgumentParser(description='Exporta dados para Obsidian')
    parser.add_argument('--data-dir', type=str,
                       default=os.getenv('DATA_PROCESSED_PATH', './data/processed'),
                       help='Diretório com dados processados')
    parser.add_argument('--output-dir', type=str,
                       default=os.getenv('OBSIDIAN_VAULT_PATH', './obsidian/vault_backup'),
                       help='Diretório do vault Obsidian')
    parser.add_argument('--create-index', action='store_true',
                       help='Cria nota índice com todas as propriedades')

    args = parser.parse_args()

    print("📝 Exportação para Obsidian")
    print("-" * 50)

    # Carrega dados
    df = load_property_data(args.data_dir)

    if df is None or df.empty:
        print("❌ Nenhum dado encontrado para exportar")
        sys.exit(1)

    print(f"📁 Carregados {len(df)} registros de propriedades")

    # Cria notas para cada propriedade
    created_files = []
    for _, prop in df.iterrows():
        filepath = create_obsidian_note(prop, args.output_dir)
        created_files.append(filepath)
        print(f"  ✓ Criado: {filepath.name}")

    # Cria índice se solicitado
    if args.create_index:
        index_path = create_index_note(df, args.output_dir)
        print(f"  ✓ Índice criado: {index_path.name}")

    print("-" * 50)
    print(f"✅ Exportação concluída! {len(created_files)} nota(s) criada(s)")


if __name__ == '__main__':
    main()

