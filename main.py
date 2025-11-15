#!/usr/bin/env python3
"""
BNI Real Estate Management System - Main CLI
"""

import sys
import argparse
import logging
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def validate_csv(args):
    """Validate CSV file"""
    from src.validators.csv_validator import validate_csv
    
    logger.info(f"Validating CSV: {args.csv_file}")
    is_valid = validate_csv(args.csv_file)
    
    if is_valid:
        logger.info("✓ CSV validation passed")
        return 0
    else:
        logger.error("✗ CSV validation failed")
        return 1


def sync_huggingface(args):
    """Sync data to Hugging Face"""
    from src.sync.hf_sync import sync_to_huggingface
    
    logger.info(f"Syncing to Hugging Face: {args.dataset_name}")
    success = sync_to_huggingface(args.csv_file, args.dataset_name, args.token)
    
    if success:
        logger.info("✓ Hugging Face sync completed")
        return 0
    else:
        logger.error("✗ Hugging Face sync failed")
        return 1


def generate_reports(args):
    """Generate IFRS reports"""
    from src.reports.ifrs_reports import IFRSReportGenerator
    from datetime import datetime
    
    logger.info(f"Generating IFRS reports from: {args.csv_file}")
    
    generator = IFRSReportGenerator(Path(args.csv_file))
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    
    success = True
    
    if args.format in ["pdf", "both"]:
        pdf_path = Path(args.output_dir) / f"ifrs_report_{timestamp}.pdf"
        pdf_path.parent.mkdir(parents=True, exist_ok=True)
        if generator.generate_pdf_report(pdf_path):
            logger.info(f"✓ PDF report generated: {pdf_path}")
        else:
            logger.error("✗ PDF report generation failed")
            success = False
    
    if args.format in ["excel", "both"]:
        excel_path = Path(args.output_dir) / f"ifrs_report_{timestamp}.xlsx"
        excel_path.parent.mkdir(parents=True, exist_ok=True)
        if generator.export_to_excel(excel_path):
            logger.info(f"✓ Excel report generated: {excel_path}")
        else:
            logger.error("✗ Excel report generation failed")
            success = False
    
    return 0 if success else 1


def generate_obsidian(args):
    """Generate Obsidian notes"""
    from src.sync.obsidian_generator import ObsidianGenerator
    
    logger.info(f"Generating Obsidian notes from: {args.csv_file}")
    
    template_dir = Path("obsidian_templates")
    output_dir = Path(args.output_dir)
    
    generator = ObsidianGenerator(Path(args.csv_file), template_dir, output_dir)
    
    # Generate all property notes
    count = generator.generate_all_property_notes()
    logger.info(f"✓ Generated {count} property notes")
    
    # Generate dashboard
    dashboard = generator.generate_dashboard()
    if dashboard:
        logger.info(f"✓ Dashboard generated: {dashboard}")
    
    return 0


def start_api(args):
    """Start the REST API server"""
    import uvicorn
    from src.api.main import app
    
    logger.info(f"Starting API server on {args.host}:{args.port}")
    
    uvicorn.run(
        app,
        host=args.host,
        port=args.port,
        reload=args.reload
    )
    
    return 0


def main():
    """Main CLI entry point"""
    parser = argparse.ArgumentParser(
        description="BNI Real Estate Management System",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Validate CSV
  python main.py validate data/raw/properties.csv
  
  # Sync to Hugging Face
  python main.py sync data/raw/properties.csv username/dataset
  
  # Generate reports
  python main.py reports data/raw/properties.csv --format both
  
  # Generate Obsidian notes
  python main.py obsidian data/raw/properties.csv
  
  # Start API server
  python main.py api --host 0.0.0.0 --port 8000
        """
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Command to execute')
    
    # Validate command
    validate_parser = subparsers.add_parser('validate', help='Validate CSV file')
    validate_parser.add_argument('csv_file', help='Path to CSV file')
    
    # Sync command
    sync_parser = subparsers.add_parser('sync', help='Sync to Hugging Face')
    sync_parser.add_argument('csv_file', help='Path to CSV file')
    sync_parser.add_argument('dataset_name', help='Hugging Face dataset name')
    sync_parser.add_argument('--token', help='Hugging Face token (or use HF_TOKEN env var)')
    
    # Reports command
    reports_parser = subparsers.add_parser('reports', help='Generate IFRS reports')
    reports_parser.add_argument('csv_file', help='Path to CSV file')
    reports_parser.add_argument('--format', choices=['pdf', 'excel', 'both'], 
                                default='both', help='Report format')
    reports_parser.add_argument('--output-dir', default='reports', 
                                help='Output directory for reports')
    
    # Obsidian command
    obsidian_parser = subparsers.add_parser('obsidian', help='Generate Obsidian notes')
    obsidian_parser.add_argument('csv_file', help='Path to CSV file')
    obsidian_parser.add_argument('--output-dir', default='obsidian_vault',
                                 help='Output directory for notes')
    
    # API command
    api_parser = subparsers.add_parser('api', help='Start REST API server')
    api_parser.add_argument('--host', default='0.0.0.0', help='Host to bind to')
    api_parser.add_argument('--port', type=int, default=8000, help='Port to bind to')
    api_parser.add_argument('--reload', action='store_true', 
                           help='Enable auto-reload for development')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return 1
    
    # Execute command
    commands = {
        'validate': validate_csv,
        'sync': sync_huggingface,
        'reports': generate_reports,
        'obsidian': generate_obsidian,
        'api': start_api
    }
    
    try:
        return commands[args.command](args)
    except Exception as e:
        logger.error(f"Error executing command: {str(e)}", exc_info=True)
        return 1


if __name__ == "__main__":
    sys.exit(main())
