SHELL:=/bin/bash

.PHONY: doc help

.PHONY: configure install

.PHONY: build clean install restart start stop

DEBUG ?= ''

API_KEY ?= '_'
API_SECRET ?= '_'
ACCESS_TOKEN ?= '_'
ACCESS_SECRET ?= '_'
SCREEN_NAME ?= '_'

COMPOSE_PROJECT_NAME ?= 'org_example_twitter-header-bot'
TMP_DIR ?= /tmp/tmp_org.example.twitter-header-bot
WORKER ?= 'org.example.twitter-header-bot'

build: ## Build worker image
	@/bin/bash -c 'source fun.sh && build'

clean: ## Remove worker container
	@/bin/bash -c 'source fun.sh && clean "${TMP_DIR}"'

help: doc
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

doc: ### Output the README documentation
	@command -v bat && bat ./README.md || cat ./README.md

install: ### Install requirements
	@/bin/bash -c "source fun.sh && install"

configure: ### API_KEY= API_SECRET= ACCESS_TOKEN= ACCESS_SECRET= SCREEN_NAME= make configure
	@/bin/bash -c "source fun.sh && configure"

restart: clear-app-cache start ## Restart worker

start: ## Run worker
	@/bin/bash -c 'source fun.sh && start'

stop: ## Stop worker
	@/bin/bash -c 'source fun.sh && stop'
