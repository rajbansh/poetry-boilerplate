#!/bin/bash
set -eo pipefail

read -p "Enter the python project name:" PROJECT_NAME
# PROJECT_NAME="boilerplate-starter"

# Replace hyphens with underscores
PROJECT_NAME="${PROJECT_NAME//-/_}"

# Create a poetry project
poetry new $PROJECT_NAME
cd $PROJECT_NAME

# Install poetry dependencies
poetry add flake8 black isort pytest pytest-cov mypy pytest-socket pytest-mock pre-commit

# Update python configuration 
cat << EOM >> setup.cfg
[coverage:run]
# Include only these source files for coverage measurement
source = ${PROJECT_NAME}

branch = True
command_line = "-m pytest"

# Omit specific files or directories from coverage measurement
omit =
    */tests/*
    */migrations/*
    */setup.py

# Parallel mode for combining coverage from multiple test runs
parallel = True

[coverage:report]
# Fail if the total coverage is below a specified threshold
fail_under = 80

# Show coverage for branches
show_missing = True

ignore_errors = True

# Include additional information about missed lines
skip_covered = True

[coverage:html]
# Directory to store HTML coverage report
directory = coverage_html_report

[flake8]
max-line-length = 160
ignore = E226,E302,E41
exclude = .git, __pycache__, build, dist
extend-ignore = E203, W503
max-complexity=10

[tool:pytest]
addopts = --disable-socket
EOM

cat << EOM >> .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v3.2.0
    hooks:
    - id: trailing-whitespace
    - id: end-of-file-fixer
    - id: check-yaml
    - id: check-added-large-files
  - repo: https://github.com/ambv/black
    rev: 22.10.0
    hooks:
    - id: black
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v2.0.0
    hooks:
    - id: flake8
EOM

# Generate Makefile
cat << EOM >> Makefile
# Variables
PYTHON = python3
PIP = pip
POETRY = poetry
PROJECT = $PROJECT_NAME

# Default target
all: install

# Rules
install: ## Install project dependencies
	\$(POETRY) install

test: ## Run tests using pytest
	\$(POETRY) run pytest

lint: ## Lint the code using flake8
	\$(POETRY) run flake8 .

format: ## Format the code using black
	\$(POETRY) run black .

sort: ## Format the code using black
	\$(POETRY) run isort .

mypy: ## Format the code using black
	\$(POETRY) run mypy .

run: ## Run main file
	\$(POETRY) run \$(PYTHON) \$(PROJECT)/main.py

check: format lint sort mypy test ## Run both linting and tests

clean: ## Clean up cache files and directories
	find . -type d -name "__pycache__" -exec rm -r {} +
	find . -type d -name "*.egg-info" -exec rm -r {} +
	rm -rf .mypy_cache .pytest_cache .coverage

build: ## Build the project using Poetry
	\$(POETRY) build

publish: ## Publish the project to PyPI using Poetry
	\$(POETRY) publish --build

coverage: ## Run tests and generate coverage report
	\$(POETRY) run pytest --cov=. --cov-report=term-missing --cov-report=html

help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*##"; printf "  %-15s %s\n", "Target", "Description"; printf "  %-15s %s\n", "------", "-----------"} /^[a-zA-Z_-]+:.*##/ { printf "  %-15s %s\n", \$\$1, \$\$2 }' \$(MAKEFILE_LIST)

# Phony targets
.PHONY: all install test lint format check clean build publish help run mypy sort coverage
EOM

# Intialize empty git
git init

# Install pre-commit hooks and run
poetry run pre-commit install
poetry run pre-commit run

# Generate sample python code and unit test
cat << EOM >> $PROJECT_NAME/main.py
def hello():
    return "hello"


if __name__ == "__main__":
    print(hello())
EOM

cat << EOM >> tests/test_main.py
from $PROJECT_NAME.main import hello

def test_hello():
    assert hello() == "hello"
EOM

touch $PROJECT_NAME/py.typed

echo "Setup git with 'git remote add origin git@github.com:User/UserRepo.git'"
echo "git push -u origin main"
