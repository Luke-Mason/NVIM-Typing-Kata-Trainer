.PHONY: test test-verbose test-cov test-cov-html clean install run help

help:  ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

install:  ## Install dependencies
	pip install -r requirements.txt

test:  ## Run all tests
	pytest

test-verbose:  ## Run tests with verbose output
	pytest -v

test-cov:  ## Run tests with coverage report
	pytest --cov=src --cov-report=term-missing

test-cov-html:  ## Generate HTML coverage report
	pytest --cov=src --cov-report=html
	@echo "Open htmlcov/index.html to view the report"

test-fast:  ## Run only fast tests (exclude slow tests)
	pytest -m "not slow"

test-watch:  ## Run tests in watch mode (requires pytest-watch)
	ptw

clean:  ## Clean up generated files
	rm -rf .pytest_cache
	rm -rf htmlcov
	rm -rf .coverage
	rm -rf __pycache__
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete

run:  ## Run the application
	python -m src.main

setup:  ## Run setup script
	@if [ -f setup.sh ]; then \
		chmod +x setup.sh && ./setup.sh; \
	elif [ -f setup.ps1 ]; then \
		powershell -ExecutionPolicy Bypass -File setup.ps1; \
	else \
		echo "No setup script found"; \
	fi

lint:  ## Run linting checks
	flake8 src --count --select=E9,F63,F7,F82 --show-source --statistics

format:  ## Format code with black (requires black)
	black src tests

typecheck:  ## Run type checking with mypy (requires mypy)
	mypy src
