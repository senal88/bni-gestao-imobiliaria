# Contributing to BNI Gestão Imobiliária

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## 🏗️ Development Setup

1. **Fork and Clone**
```bash
git clone https://github.com/YOUR_USERNAME/bni-gestao-imobiliaria.git
cd bni-gestao-imobiliaria
```

2. **Create Virtual Environment**
```bash
python -m venv venv
source venv/bin/activate
```

3. **Install Dependencies**
```bash
pip install -r requirements.txt
pip install -e .  # Install in editable mode
```

4. **Run Tests**
```bash
pytest tests/ -v
```

## 🔀 Workflow

1. **Create a Branch**
```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/bug-description
```

2. **Make Changes**
- Write clean, documented code
- Follow existing code style
- Add tests for new features
- Update documentation

3. **Test Your Changes**
```bash
# Run all tests
pytest tests/ -v

# Run specific test file
pytest tests/test_api.py -v

# With coverage
pytest tests/ --cov=src --cov-report=html
```

4. **Commit**
```bash
git add .
git commit -m "feat: add new feature"
# or
git commit -m "fix: resolve issue with X"
```

5. **Push and Create PR**
```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

## 📝 Commit Message Convention

Use conventional commits:

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `test:` - Adding or updating tests
- `refactor:` - Code refactoring
- `style:` - Code style changes (formatting)
- `chore:` - Maintenance tasks

Examples:
```
feat: add support for multi-currency in reports
fix: handle NaN values in CSV loading
docs: update API documentation with new endpoints
test: add tests for portfolio statistics
```

## 🧪 Testing Guidelines

### Writing Tests

1. **Location**: Place tests in `tests/` directory
2. **Naming**: Test files should start with `test_`
3. **Structure**: Group related tests in classes

Example:
```python
import pytest
from src.validators.csv_validator import PropertySchemaValidator

def test_valid_csv():
    """Test validation of valid CSV"""
    validator = PropertySchemaValidator()
    assert validator.validate_file("test.csv") is True

def test_invalid_csv():
    """Test validation of invalid CSV"""
    validator = PropertySchemaValidator()
    assert validator.validate_file("invalid.csv") is False
```

### Running Tests

```bash
# All tests
pytest

# Specific file
pytest tests/test_api.py

# Specific test
pytest tests/test_api.py::test_root_endpoint

# With verbose output
pytest -v

# With coverage
pytest --cov=src

# Generate HTML coverage report
pytest --cov=src --cov-report=html
```

## 📚 Documentation

### Code Documentation

- Use docstrings for all public functions/classes
- Follow Google or NumPy docstring style
- Include parameter types and return values

Example:
```python
def validate_csv(filepath: str) -> bool:
    """
    Validate a CSV file against property schema
    
    Args:
        filepath: Path to CSV file to validate
        
    Returns:
        True if valid, False otherwise
        
    Example:
        >>> validate_csv("properties.csv")
        True
    """
    pass
```

### Documentation Files

- Update `README.md` for user-facing changes
- Update `docs/DOCUMENTATION.md` for technical details
- Update `QUICKSTART.md` for setup changes

## 🎨 Code Style

### Python Style

- Follow PEP 8
- Use type hints where applicable
- Maximum line length: 100 characters
- Use meaningful variable names

Example:
```python
from typing import List, Optional

def get_properties(tipo: Optional[str] = None) -> List[Property]:
    """Get properties with optional filtering"""
    pass
```

### Import Order

1. Standard library imports
2. Third-party imports
3. Local imports

```python
import os
from pathlib import Path

import pandas as pd
from fastapi import FastAPI

from src.validators.csv_validator import PropertySchemaValidator
```

## 🔍 Code Review

Pull requests will be reviewed for:

1. **Functionality**: Does it work as intended?
2. **Tests**: Are there adequate tests?
3. **Documentation**: Is code well-documented?
4. **Style**: Does it follow project conventions?
5. **Performance**: Any obvious performance issues?

## 🐛 Bug Reports

When reporting bugs, include:

1. **Description**: Clear description of the issue
2. **Steps to Reproduce**: How to reproduce the bug
3. **Expected Behavior**: What should happen
4. **Actual Behavior**: What actually happens
5. **Environment**: OS, Python version, etc.
6. **Screenshots**: If applicable

Template:
```markdown
**Description**
Brief description of the bug

**To Reproduce**
1. Step 1
2. Step 2
3. See error

**Expected Behavior**
What should happen

**Actual Behavior**
What actually happens

**Environment**
- OS: Ubuntu 22.04
- Python: 3.11
- Version: 1.0.0

**Additional Context**
Any other relevant information
```

## 💡 Feature Requests

When suggesting features:

1. **Use Case**: Why is this needed?
2. **Proposed Solution**: How should it work?
3. **Alternatives**: Other approaches considered
4. **Additional Context**: Any other information

## 🔒 Security

If you discover a security vulnerability:

1. **DO NOT** open a public issue
2. Email the maintainers directly
3. Provide detailed information
4. Allow time for a fix before disclosure

## 📋 Checklist Before Submitting PR

- [ ] Code follows project style guidelines
- [ ] Tests added/updated for changes
- [ ] All tests pass locally
- [ ] Documentation updated
- [ ] Commit messages follow convention
- [ ] No commented-out code
- [ ] No unnecessary dependencies added
- [ ] Branch is up to date with main

## 🤝 Code of Conduct

### Our Pledge

We pledge to make participation in our project a harassment-free experience for everyone.

### Our Standards

**Positive behavior includes:**
- Being respectful and inclusive
- Accepting constructive criticism
- Focusing on what's best for the community
- Showing empathy towards others

**Unacceptable behavior includes:**
- Harassment or discriminatory comments
- Personal or political attacks
- Public or private harassment
- Publishing others' private information

### Enforcement

Instances of unacceptable behavior may be reported to project maintainers.

## 📞 Getting Help

- **Questions**: Open a GitHub Discussion
- **Bugs**: Open a GitHub Issue
- **Features**: Open a GitHub Issue with [Feature Request] tag
- **Chat**: Join our community chat (if available)

## 🙏 Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes
- Project documentation

Thank you for contributing to BNI Gestão Imobiliária! 🎉
