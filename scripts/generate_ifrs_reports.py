#!/usr/bin/env python3
"""
Script de geração de relatórios IFRS.
Gera relatórios financeiros no padrão IFRS a partir dos dados do portfólio.
"""

import os
import sys
import argparse
from pathlib import Path
from datetime import datetime
from dotenv import load_dotenv
import pandas as pd
from reportlab.lib.pagesizes import letter, A4
from reportlab.lib import colors
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_RIGHT

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

    # Carrega o primeiro arquivo encontrado
    df = pd.read_csv(csv_files[0])
    return df


def calculate_portfolio_value(df):
    """Calcula o valor total do portfólio."""
    if 'valor_avaliacao' in df.columns:
        return df['valor_avaliacao'].sum()
    return 0


def generate_ifrs_report_pdf(df, output_path, periodo):
    """Gera relatório IFRS em PDF."""
    doc = SimpleDocTemplate(str(output_path), pagesize=A4)
    story = []

    # Estilos
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=18,
        textColor=colors.HexColor('#1a1a1a'),
        spaceAfter=30,
        alignment=TA_CENTER
    )

    # Título
    title = Paragraph(f"Relatório IFRS - Portfólio BNI<br/>{periodo}", title_style)
    story.append(title)
    story.append(Spacer(1, 0.3*inch))

    # Resumo Executivo
    story.append(Paragraph("<b>RESUMO EXECUTIVO</b>", styles['Heading2']))
    story.append(Spacer(1, 0.2*inch))

    total_properties = len(df)
    total_value = calculate_portfolio_value(df)

    summary_data = [
        ['Métrica', 'Valor'],
        ['Total de Propriedades', f"{total_properties}"],
        ['Valor Total do Portfólio', f"R$ {total_value:,.2f}"],
        ['Valor Médio por Propriedade', f"R$ {total_value/total_properties:,.2f}" if total_properties > 0 else "R$ 0,00"],
    ]

    summary_table = Table(summary_data, colWidths=[4*inch, 2*inch])
    summary_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 12),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
        ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
        ('GRID', (0, 0), (-1, -1), 1, colors.black)
    ]))

    story.append(summary_table)
    story.append(Spacer(1, 0.3*inch))

    # Detalhamento por Propriedade
    story.append(Paragraph("<b>DETALHAMENTO POR PROPRIEDADE</b>", styles['Heading2']))
    story.append(Spacer(1, 0.2*inch))

    # Prepara dados da tabela
    if 'codigo' in df.columns and 'nome' in df.columns and 'valor_avaliacao' in df.columns:
        property_data = [['Código', 'Nome', 'Valor (R$)']]

        for _, row in df.iterrows():
            property_data.append([
                str(row.get('codigo', 'N/A')),
                str(row.get('nome', 'N/A'))[:40],  # Limita tamanho
                f"{row.get('valor_avaliacao', 0):,.2f}"
            ])

        property_table = Table(property_data, colWidths=[1.5*inch, 3*inch, 1.5*inch])
        property_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('ALIGN', (2, 1), (2, -1), 'RIGHT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 10),
            ('FONTSIZE', (0, 1), (-1, -1), 8),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
            ('GRID', (0, 0), (-1, -1), 1, colors.black),
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.lightgrey])
        ]))

        story.append(property_table)

    # Rodapé
    story.append(Spacer(1, 0.3*inch))
    footer_text = f"Gerado em: {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}"
    story.append(Paragraph(footer_text, styles['Normal']))

    # Gera PDF
    doc.build(story)
    print(f"✅ Relatório PDF gerado: {output_path}")


def generate_ifrs_report_excel(df, output_path, periodo):
    """Gera relatório IFRS em Excel."""
    with pd.ExcelWriter(output_path, engine='xlsxwriter') as writer:
        workbook = writer.book

        # Resumo Executivo
        summary_df = pd.DataFrame({
            'Métrica': ['Total de Propriedades', 'Valor Total do Portfólio', 'Valor Médio por Propriedade'],
            'Valor': [
                len(df),
                calculate_portfolio_value(df),
                calculate_portfolio_value(df) / len(df) if len(df) > 0 else 0
            ]
        })
        summary_df.to_excel(writer, sheet_name='Resumo', index=False)

        # Detalhamento
        df.to_excel(writer, sheet_name='Propriedades', index=False)

        # Formatação
        summary_sheet = writer.sheets['Resumo']
        summary_sheet.set_column('A:A', 30)
        summary_sheet.set_column('B:B', 20)

    print(f"✅ Relatório Excel gerado: {output_path}")


def main():
    parser = argparse.ArgumentParser(description='Gera relatórios IFRS')
    parser.add_argument('--data-dir', type=str,
                       default=os.getenv('DATA_PROCESSED_PATH', './data/processed'),
                       help='Diretório com dados processados')
    parser.add_argument('--output-dir', type=str,
                       default=os.getenv('IFRS_REPORTS_PATH', './reports/ifrs'),
                       help='Diretório para salvar relatórios')
    parser.add_argument('--format', type=str, choices=['pdf', 'xlsx', 'both'],
                       default=os.getenv('IFRS_REPORTS_FORMAT', 'pdf'),
                       help='Formato do relatório')
    parser.add_argument('--periodo', type=str,
                       default=datetime.now().strftime('%Y-%m'),
                       help='Período do relatório (YYYY-MM)')

    args = parser.parse_args()

    print("📊 Geração de Relatórios IFRS")
    print("-" * 50)

    # Cria diretório de saída
    output_path = Path(args.output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    # Carrega dados
    df = load_property_data(args.data_dir)

    if df is None or df.empty:
        print("❌ Nenhum dado encontrado para gerar relatórios")
        sys.exit(1)

    print(f"📁 Carregados {len(df)} registros de propriedades")

    # Gera relatórios
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')

    if args.format in ['pdf', 'both']:
        pdf_path = output_path / f"relatorio_ifrs_{args.periodo}_{timestamp}.pdf"
        generate_ifrs_report_pdf(df, pdf_path, args.periodo)

    if args.format in ['xlsx', 'both']:
        xlsx_path = output_path / f"relatorio_ifrs_{args.periodo}_{timestamp}.xlsx"
        generate_ifrs_report_excel(df, xlsx_path, args.periodo)

    print("-" * 50)
    print("✅ Geração de relatórios concluída!")


if __name__ == '__main__':
    main()

