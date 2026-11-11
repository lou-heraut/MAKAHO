# Les commandes de MAKAHO. `make` seul les liste.

PY := .python_env/bin/python

.DEFAULT_GOAL := help
.PHONY: help install run test test-live lint measure

help:        ## liste des commandes
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | \
	  awk -F':.*## ' '{printf "  make %-10s %s\n", $$1, $$2}'

install:     ## crée .python_env et y installe MAKAHO et ses outils
	python3 -m venv .python_env
	$(PY) -m pip install -e '.[dev]'

run:         ## lance MAKAHO en développement, réglages lus dans .env
	$(PY) -m flask --app makaho run --debug

test:        ## tests hors ligne, sur un card-api simulé
	$(PY) -m pytest

test-live:   ## tests contre le card-api en ligne, avec la clé de .env
	MAKAHO_LIVE=1 $(PY) -m pytest tests/test_live.py -v

lint:        ## lint (ruff, version épinglée dans pyproject)
	$(PY) -m ruff check src tests scripts

measure:     ## refait la mesure de l'audit (section 5) sur card-api, avec la clé
	$(PY) -m pip install -q -e '.[measure]'
	$(PY) scripts/mesure_sampling.py
