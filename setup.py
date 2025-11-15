from setuptools import setup, find_packages

setup(
    name="bni-gestao-imobiliaria",
    version="0.1.0",
    description="Sistema de gestão imobiliária para portfólio de 38 propriedades da BNI",
    author="BNI Team",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    install_requires=[
        "fastapi>=0.104.1",
        "uvicorn[standard]>=0.24.0",
        "pydantic>=2.5.0",
        "psycopg2-binary>=2.9.9",
        "sqlalchemy>=2.0.23",
        "pandas>=2.1.3",
        "numpy>=1.26.2",
        "datasets>=2.15.0",
        "huggingface-hub>=0.19.4",
        "jsonschema>=4.20.0",
        "cerberus>=1.3.5",
        "reportlab>=4.0.7",
        "openpyxl>=3.1.2",
        "python-dotenv>=1.0.0",
        "pyyaml>=6.0.1",
    ],
    extras_require={
        "dev": [
            "pytest>=7.4.3",
            "pytest-cov>=4.1.0",
            "pytest-asyncio>=0.21.1",
            "httpx>=0.25.2",
        ]
    },
    python_requires=">=3.9",
)
