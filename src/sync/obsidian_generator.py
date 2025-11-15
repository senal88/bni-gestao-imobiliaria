"""
Obsidian Integration for BNI Real Estate Portfolio
Generates Markdown notes from property data
"""

import pandas as pd
from pathlib import Path
from datetime import datetime
from typing import Optional
import logging
import re

logger = logging.getLogger(__name__)


class ObsidianGenerator:
    """Generate Obsidian-compatible Markdown notes from property data"""
    
    def __init__(self, properties_csv: Path, template_dir: Path, output_dir: Path):
        """
        Initialize Obsidian generator
        
        Args:
            properties_csv: Path to properties CSV file
            template_dir: Directory containing Markdown templates
            output_dir: Directory to save generated notes
        """
        self.properties_csv = properties_csv
        self.template_dir = template_dir
        self.output_dir = output_dir
        self.df = None
        self._load_data()
    
    def _load_data(self):
        """Load property data from CSV"""
        try:
            self.df = pd.read_csv(self.properties_csv)
            logger.info(f"Loaded {len(self.df)} properties")
        except Exception as e:
            logger.error(f"Error loading data: {str(e)}")
            self.df = pd.DataFrame()
    
    def _load_template(self, template_name: str) -> str:
        """Load a Markdown template"""
        template_path = self.template_dir / template_name
        try:
            with open(template_path, 'r', encoding='utf-8') as f:
                return f.read()
        except Exception as e:
            logger.error(f"Error loading template {template_name}: {str(e)}")
            return ""
    
    def _replace_placeholders(self, template: str, data: dict) -> str:
        """Replace template placeholders with actual data"""
        result = template
        for key, value in data.items():
            placeholder = f"{{{{{key}}}}}"
            result = result.replace(placeholder, str(value))
        return result
    
    def generate_property_note(self, property_id: str) -> Optional[Path]:
        """
        Generate an Obsidian note for a single property
        
        Args:
            property_id: Property ID
            
        Returns:
            Path to generated note, or None if failed
        """
        if self.df.empty:
            logger.error("No data loaded")
            return None
        
        # Find property in dataframe
        prop_data = self.df[self.df['id_propriedade'] == property_id]
        if prop_data.empty:
            logger.error(f"Property {property_id} not found")
            return None
        
        prop = prop_data.iloc[0].to_dict()
        
        # Calculate additional fields
        prop['valorizacao'] = prop['valor_atual'] - prop['valor_aquisicao']
        prop['valorizacao_pct'] = (prop['valorizacao'] / prop['valor_aquisicao'] * 100) if prop['valor_aquisicao'] > 0 else 0
        prop['renda_anual'] = prop.get('renda_mensal', 0) * 12
        prop['yield_anual'] = (prop['renda_anual'] / prop['valor_atual'] * 100) if prop['valor_atual'] > 0 else 0
        prop['date'] = datetime.now().strftime('%Y-%m-%d')
        
        # Format numbers
        prop['valor_aquisicao'] = f"{prop['valor_aquisicao']:,.2f}"
        prop['valor_atual'] = f"{prop['valor_atual']:,.2f}"
        prop['valorizacao'] = f"{prop['valorizacao']:,.2f}"
        prop['valorizacao_pct'] = f"{prop['valorizacao_pct']:.2f}"
        prop['renda_mensal'] = f"{prop.get('renda_mensal', 0):,.2f}"
        prop['renda_anual'] = f"{prop['renda_anual']:,.2f}"
        prop['yield_anual'] = f"{prop['yield_anual']:.2f}"
        prop['area_m2'] = f"{prop['area_m2']:.2f}"
        
        # Load template and replace placeholders
        template = self._load_template('property_template.md')
        if not template:
            return None
        
        content = self._replace_placeholders(template, prop)
        
        # Save note
        self.output_dir.mkdir(parents=True, exist_ok=True)
        safe_name = re.sub(r'[^\w\s-]', '', prop['nome']).strip().replace(' ', '_')
        note_path = self.output_dir / f"{property_id}_{safe_name}.md"
        
        try:
            with open(note_path, 'w', encoding='utf-8') as f:
                f.write(content)
            logger.info(f"Generated note: {note_path}")
            return note_path
        except Exception as e:
            logger.error(f"Error saving note: {str(e)}")
            return None
    
    def generate_all_property_notes(self) -> int:
        """
        Generate Obsidian notes for all properties
        
        Returns:
            Number of notes generated
        """
        if self.df.empty:
            logger.error("No data loaded")
            return 0
        
        count = 0
        for _, row in self.df.iterrows():
            property_id = row['id_propriedade']
            if self.generate_property_note(property_id):
                count += 1
        
        logger.info(f"Generated {count} property notes")
        return count
    
    def generate_dashboard(self) -> Optional[Path]:
        """
        Generate portfolio dashboard note
        
        Returns:
            Path to generated dashboard, or None if failed
        """
        if self.df.empty:
            logger.error("No data loaded")
            return None
        
        # Calculate statistics
        total_properties = len(self.df)
        total_value = self.df['valor_atual'].sum()
        monthly_income = self.df['renda_mensal'].sum()
        annual_income = monthly_income * 12
        average_yield = (annual_income / total_value * 100) if total_value > 0 else 0
        
        # Status counts
        occupied_count = len(self.df[self.df['status'] == 'Ocupada'])
        vacant_count = len(self.df[self.df['status'] == 'Vaga'])
        reform_count = len(self.df[self.df['status'] == 'Em Reforma'])
        sale_count = len(self.df[self.df['status'] == 'À Venda'])
        
        occupied_pct = (occupied_count / total_properties * 100) if total_properties > 0 else 0
        vacant_pct = (vacant_count / total_properties * 100) if total_properties > 0 else 0
        
        # Type distribution
        type_counts = self.df.groupby('tipo').agg({
            'id_propriedade': 'count',
            'valor_atual': 'sum',
            'renda_mensal': 'sum'
        }).to_dict()
        
        # Acquisition and appreciation
        total_acquisition = self.df['valor_aquisicao'].sum()
        total_appreciation = total_value - total_acquisition
        appreciation_pct = (total_appreciation / total_acquisition * 100) if total_acquisition > 0 else 0
        
        # Prepare data dictionary
        data = {
            'date': datetime.now().strftime('%Y-%m-%d'),
            'total_properties': total_properties,
            'total_value': f"{total_value:,.2f}",
            'monthly_income': f"{monthly_income:,.2f}",
            'annual_income': f"{annual_income:,.2f}",
            'average_yield': f"{average_yield:.2f}",
            'occupied_count': occupied_count,
            'occupied_pct': f"{occupied_pct:.1f}",
            'vacant_count': vacant_count,
            'vacant_pct': f"{vacant_pct:.1f}",
            'reform_count': reform_count,
            'sale_count': sale_count,
            'total_acquisition': f"{total_acquisition:,.2f}",
            'total_current': f"{total_value:,.2f}",
            'total_appreciation': f"{total_appreciation:,.2f}",
            'appreciation_pct': f"{appreciation_pct:.2f}",
            'next_update': (datetime.now().replace(day=1, month=datetime.now().month % 12 + 1)).strftime('%Y-%m-%d'),
        }
        
        # Add type distribution (with defaults)
        for tipo in ['Residencial', 'Comercial', 'Industrial', 'Terreno']:
            prefix = tipo[:3].lower()
            data[f'{prefix}_count'] = type_counts.get('id_propriedade', {}).get(tipo, 0)
            data[f'{prefix}_value'] = f"{type_counts.get('valor_atual', {}).get(tipo, 0):,.2f}"
            data[f'{prefix}_income'] = f"{type_counts.get('renda_mensal', {}).get(tipo, 0):,.2f}"
        
        # Top 5 properties by value
        top_by_value = self.df.nlargest(5, 'valor_atual')
        for i, (_, row) in enumerate(top_by_value.iterrows(), 1):
            data[f'top{i}_name'] = row['nome']
            data[f'top{i}_value'] = f"{row['valor_atual']:,.2f}"
        
        # Top 5 properties by income
        top_by_income = self.df.nlargest(5, 'renda_mensal')
        for i, (_, row) in enumerate(top_by_income.iterrows(), 1):
            data[f'income_top{i}_name'] = row['nome']
            data[f'income_top{i}_value'] = f"{row['renda_mensal']:,.2f}"
        
        # Load template and replace placeholders
        template = self._load_template('portfolio_dashboard.md')
        if not template:
            return None
        
        content = self._replace_placeholders(template, data)
        
        # Save dashboard
        self.output_dir.mkdir(parents=True, exist_ok=True)
        dashboard_path = self.output_dir / "Portfolio_Dashboard.md"
        
        try:
            with open(dashboard_path, 'w', encoding='utf-8') as f:
                f.write(content)
            logger.info(f"Generated dashboard: {dashboard_path}")
            return dashboard_path
        except Exception as e:
            logger.error(f"Error saving dashboard: {str(e)}")
            return None


if __name__ == "__main__":
    import sys
    
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    if len(sys.argv) < 2:
        print("Usage: python obsidian_generator.py <csv_file> [output_dir]")
        sys.exit(1)
    
    csv_file = Path(sys.argv[1])
    output_dir = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("obsidian_vault")
    template_dir = Path("obsidian_templates")
    
    generator = ObsidianGenerator(csv_file, template_dir, output_dir)
    
    # Generate all notes
    generator.generate_all_property_notes()
    generator.generate_dashboard()
