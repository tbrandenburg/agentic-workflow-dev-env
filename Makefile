.DEFAULT_GOAL := help

IMAGE ?= ghcr.io/tbrandenburg/agentic-workflow-dev-env:latest
COMPOSE ?= docker compose
CACERT ?=
BUMP ?= patch
comma := ,

.PHONY: help build up interactive up-srt down logs release

help: ## Show available targets

	@grep -E '^[a-zA-Z0-9_-]+:.*## ' $(MAKEFILE_LIST) | \
		sed -E 's/:.*## /|/' | awk -F'|' '{printf "  %-10s %s\n", $$1, $$2}'

build: ## Build the image; optionally CACERT=/path/to/corporate-ca.pem

	DOCKER_BUILDKIT=1 docker build \
		$(if $(CACERT),--secret id=cacert$(comma)src=$(CACERT)) \
		--tag $(IMAGE) .

up: ## Start the standard development environment

	IMAGE=$(IMAGE) $(COMPOSE) up --build

interactive: ## Build the image and open an interactive shell in /workspace

	IMAGE=$(IMAGE) $(COMPOSE) run --build --rm workflow bash

up-srt: ## Start with nested SRT sandboxing enabled (trusted local development only)

	IMAGE=$(IMAGE) $(COMPOSE) -f compose.yaml -f compose.srt.yaml up --build

down: ## Stop services while preserving persistent volumes

	$(COMPOSE) down

logs: ## Follow service logs

	$(COMPOSE) logs --follow

release: ## Bump VERSION, commit, tag, and push; use BUMP=major|minor|patch

	@set -eu; \
	current=$$(tr -d '[:space:]' < VERSION); \
	case "$$current" in \
		[0-9]*.[0-9]*.[0-9]*) ;; \
		*) echo "VERSION must contain MAJOR.MINOR.PATCH" >&2; exit 1 ;; \
	esac; \
	git diff --quiet && git diff --cached --quiet && test -z "$$(git status --porcelain)" || { echo "working tree must be clean" >&2; exit 1; }; \
	IFS=.; set -- $$current; major=$$1; minor=$$2; patch=$$3; \
	case "$(BUMP)" in \
		major) next="$$((major + 1)).0.0" ;; \
		minor) next="$$major.$$((minor + 1)).0" ;; \
		patch) next="$$major.$$minor.$$((patch + 1))" ;; \
		*) echo "BUMP must be major, minor, or patch" >&2; exit 1 ;; \
	esac; \
	printf '%s\n' "$$next" > VERSION; \
	git add VERSION; \
	git commit -m "release: v$$next"; \
	git tag -a "v$$next" -m "Release v$$next"; \
	git push origin HEAD; \
	git push origin "v$$next"; \
	gh release create "v$$next" --title "v$$next" --generate-notes --verify-tag
