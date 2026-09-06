.DEFAULT_GOAL := help

IMAGE ?= ghcr.io/OWNER/agentic-workflow-dev-env:latest
COMPOSE ?= docker compose
CACERT ?=
comma := ,

.PHONY: help build up up-srt down logs

help: ## Show available targets

	@grep -E '^[a-zA-Z0-9_-]+:.*## ' $(MAKEFILE_LIST) | \
		sed -E 's/:.*## /|/' | awk -F'|' '{printf "  %-10s %s\n", $$1, $$2}'

build: ## Build the image; optionally CACERT=/path/to/corporate-ca.pem

	DOCKER_BUILDKIT=1 docker build \
		$(if $(CACERT),--secret id=cacert$(comma)src=$(CACERT)) \
		--tag $(IMAGE) .

up: ## Start the standard development environment

	IMAGE=$(IMAGE) $(COMPOSE) up --build

up-srt: ## Start with nested SRT sandboxing enabled (trusted local development only)

	IMAGE=$(IMAGE) $(COMPOSE) -f compose.yaml -f compose.srt.yaml up --build

down: ## Stop services while preserving persistent volumes

	$(COMPOSE) down

logs: ## Follow service logs

	$(COMPOSE) logs --follow
