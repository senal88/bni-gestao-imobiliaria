"""
Hugging Face Dataset Synchronization
Syncs BNI property portfolio data with Hugging Face Datasets
"""

import os
from pathlib import Path
from typing import Optional
import logging
from datetime import datetime

import pandas as pd
from datasets import Dataset, DatasetDict, load_dataset
from huggingface_hub import HfApi, login

logger = logging.getLogger(__name__)


class HuggingFaceSync:
    """Synchronize property data with Hugging Face Datasets"""
    
    def __init__(self, dataset_name: str, token: Optional[str] = None):
        """
        Initialize Hugging Face sync
        
        Args:
            dataset_name: Name of the dataset on Hugging Face (e.g., "username/bni-properties")
            token: Hugging Face API token (or use HF_TOKEN env var)
        """
        self.dataset_name = dataset_name
        self.token = token or os.getenv("HF_TOKEN")
        self.api = HfApi()
        
        if self.token:
            login(token=self.token)
    
    def upload_csv(self, csv_path: Path, split: str = "train") -> bool:
        """
        Upload CSV data to Hugging Face dataset
        
        Args:
            csv_path: Path to CSV file
            split: Dataset split name (e.g., "train", "test")
            
        Returns:
            True if successful, False otherwise
        """
        try:
            # Load CSV into pandas DataFrame
            df = pd.read_csv(csv_path)
            logger.info(f"Loaded {len(df)} records from {csv_path}")
            
            # Convert to Hugging Face Dataset
            dataset = Dataset.from_pandas(df)
            
            # Create DatasetDict
            dataset_dict = DatasetDict({split: dataset})
            
            # Push to Hugging Face Hub
            logger.info(f"Pushing dataset to {self.dataset_name}")
            dataset_dict.push_to_hub(
                self.dataset_name,
                token=self.token,
                private=True  # Keep private for internal use
            )
            
            logger.info("Dataset uploaded successfully")
            return True
            
        except Exception as e:
            logger.error(f"Error uploading dataset: {str(e)}")
            return False
    
    def download_dataset(self, output_dir: Path, split: str = "train") -> Optional[pd.DataFrame]:
        """
        Download dataset from Hugging Face
        
        Args:
            output_dir: Directory to save downloaded data
            split: Dataset split to download
            
        Returns:
            DataFrame with downloaded data, or None if failed
        """
        try:
            logger.info(f"Downloading dataset {self.dataset_name}")
            
            # Load dataset from Hub
            dataset = load_dataset(self.dataset_name, split=split, token=self.token)
            
            # Convert to pandas DataFrame
            df = dataset.to_pandas()
            
            # Save to CSV
            output_dir.mkdir(parents=True, exist_ok=True)
            output_path = output_dir / f"properties_{split}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
            df.to_csv(output_path, index=False)
            
            logger.info(f"Dataset saved to {output_path}")
            return df
            
        except Exception as e:
            logger.error(f"Error downloading dataset: {str(e)}")
            return None
    
    def sync_bidirectional(self, local_csv: Path, output_dir: Path) -> bool:
        """
        Perform bidirectional sync between local and Hugging Face
        
        Args:
            local_csv: Path to local CSV file
            output_dir: Directory for downloaded data
            
        Returns:
            True if successful, False otherwise
        """
        try:
            # First, upload local changes
            logger.info("Uploading local changes to Hugging Face...")
            if not self.upload_csv(local_csv):
                return False
            
            # Then, download to verify
            logger.info("Downloading to verify sync...")
            df = self.download_dataset(output_dir)
            
            if df is not None:
                logger.info(f"Sync completed: {len(df)} records")
                return True
            
            return False
            
        except Exception as e:
            logger.error(f"Error in bidirectional sync: {str(e)}")
            return False
    
    def get_dataset_info(self) -> Optional[dict]:
        """
        Get information about the dataset
        
        Returns:
            Dictionary with dataset metadata, or None if failed
        """
        try:
            info = self.api.dataset_info(self.dataset_name, token=self.token)
            return {
                "id": info.id,
                "author": info.author,
                "sha": info.sha,
                "last_modified": info.lastModified,
                "private": info.private,
                "downloads": info.downloads,
            }
        except Exception as e:
            logger.error(f"Error getting dataset info: {str(e)}")
            return None


def sync_to_huggingface(csv_path: str, dataset_name: str, token: Optional[str] = None) -> bool:
    """
    Convenience function to sync CSV to Hugging Face
    
    Args:
        csv_path: Path to CSV file
        dataset_name: Hugging Face dataset name
        token: API token (optional)
        
    Returns:
        True if successful, False otherwise
    """
    sync = HuggingFaceSync(dataset_name, token)
    return sync.upload_csv(Path(csv_path))


if __name__ == "__main__":
    import sys
    
    # Configure logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    if len(sys.argv) < 3:
        print("Usage: python hf_sync.py <csv_file> <dataset_name> [token]")
        print("Example: python hf_sync.py data/properties.csv username/bni-properties")
        sys.exit(1)
    
    csv_file = sys.argv[1]
    dataset_name = sys.argv[2]
    token = sys.argv[3] if len(sys.argv) > 3 else None
    
    success = sync_to_huggingface(csv_file, dataset_name, token)
    sys.exit(0 if success else 1)
