#!/bin/bash
set -eo pipefail

read -p "Enter the python project name:" PROJECT_NAME
# PROJECT_NAME="boilerplate-starter"

# Replace hyphens with underscores
PROJECT_NAME="${PROJECT_NAME//-/_}"

# Path to the virtual environment
VENV_PATH="venv"

# Create a folder scaffolding
mkdir -p $PROJECT_NAME/$PROJECT_NAME
mkdir -p $PROJECT_NAME/tests
touch $PROJECT_NAME/$PROJECT_NAME/__init__.py
touch $PROJECT_NAME/tests/__init__.py

cd $PROJECT_NAME
python3 -m ${VENV_PATH} ${VENV_PATH}
source ${VENV_PATH}/bin/activate

# Install python dependencies
python3 -m pip install flake8 black isort pytest pytest-cov mypy pytest-socket pytest-mock pre-commit ruff build

cat << EOM > pyproject.toml
[project]
name = "starter"
version = "0.1.0"
description = ""
authors = [{name="R Raj", email="rajbansh4@gmail.com"}]
readme = "README.md"
dependencies = [
    # List of dependencies:
    # "requests>=2.24.0",
]
[tool.setuptools.packages.find]
where = ["$PROJECT_NAME"]

[build-system]
requires = ["setuptools>=42", "wheel"]
build-backend = "setuptools.build_meta"
EOM


# Update python configuration 
cat << EOM > setup.cfg
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
exclude = .git, __pycache__, build, dist, ${VENV_PATH}
extend-ignore = E203, W503
max-complexity=10

[tool:pytest]
addopts = --disable-socket
EOM

cat << EOM > .pre-commit-config.yaml
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
cat << EOM > Makefile
# Variables
PYTHON = python3
PIP = pip
PROJECT = $PROJECT_NAME

# Path to the virtual environment
VENV_PATH = $VENV_PATH

# Default target
all: install

# Rules
add: ## Git add
	. \$(VENV_PATH)/bin/activate && pip freeze > requirements.txt

install: ## Install project dependencies
	. venv/bin/activate && pip install -r requirements.txt

test: ## Run tests using pytest
	. \$(VENV_PATH)/bin/activate && pytest

lint: ## Lint the code using flake8
	. \$(VENV_PATH)/bin/activate && flake8 .

format: ## Format the code using black
	. \$(VENV_PATH)/bin/activate && black .

sort: ## Format the code using black
	. \$(VENV_PATH)/bin/activate && isort .

mypy: ## Format the code using black
	. \$(VENV_PATH)/bin/activate && mypy .

ruff: ## Ruff check
	. \$(VENV_PATH)/bin/activate && ruff check

fix: ## Ruff fix
	. \$(VENV_PATH)/bin/activate && ruff check --fix

run: ## Run main file
	. \$(VENV_PATH)/bin/activate && \$(PYTHON) \$(PROJECT)/main.py

check: format lint sort mypy test add ## Run both linting and tests

clean: ## Clean up cache files and directories
	find . -type d -name "__pycache__" -exec rm -r {} +
	find . -type d -name "*.egg-info" -exec rm -r {} +
	rm -rf .mypy_cache .pytest_cache .coverage

build: ## Build the project
	. \$(VENV_PATH)/bin/activate && \$(PYTHON) -m build

coverage: ## Run tests and generate coverage report
	. \$(VENV_PATH)/bin/activate && pytest --cov=. --cov-report=term-missing --cov-report=html

help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*##"; printf "  %-15s %s\n", "Target", "Description"; printf "  %-15s %s\n", "------", "-----------"} /^[a-zA-Z_-]+:.*##/ { printf "  %-15s %s\n", \$\$1, \$\$2 }' \$(MAKEFILE_LIST)

# Phony targets
.PHONY: all install test lint format check clean build publish help run mypy sort coverage ruff fix
EOM

# Intialize empty git
git init

# Install pre-commit hooks and run
. $VENV_PATH/bin/activate && pre-commit install
. $VENV_PATH/bin/activate && pre-commit run

# Generate sample python code and unit test
cat << EOM > $PROJECT_NAME/hello.py
def hello():
    return "hello"
EOM

cat << EOM > $PROJECT_NAME/main.py
from $PROJECT_NAME.hello import hello


if __name__ == "__main__":
    print(hello())
EOM

cat << EOM > tests/test_main.py
from $PROJECT_NAME.hello import hello

def test_hello():
    assert hello() == "hello"
EOM

touch $PROJECT_NAME/py.typed

pip freeze > requirements.txt
. $VENV_PATH/bin/activate && pip install .

echo "Setup git with 'git remote add origin git@github.com:User/UserRepo.git'"
echo "git push -u origin main"
