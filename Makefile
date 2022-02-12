ifeq ($(OS),Windows_NT)
    detected_OS := Windows
else
    detected_OS := $(shell sh -c 'uname 2>/dev/null || echo Unknown')
endif

# Executables (local)
DOCKER_COMP = docker-compose

# Docker containers
PHP_CONT = $(DOCKER_COMP) exec php

# Executables
PHP      = $(PHP_CONT) php
COMPOSER = $(PHP_CONT) composer
SYMFONY  = $(PHP_CONT) bin/console
NPM      = $(PHP_CONT) npm

# Misc
.DEFAULT_GOAL = help
.PHONY        = help build up install down logs sh composer vendor sf cc

## —— 🎵 🐳 The Symfony-docker Makefile 🐳 🎵 ——————————————————————————————————
help: ## Outputs this help screen
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

## —— Docker 🐳 ————————————————————————————————————————————————————————————————
build: ## Builds the Docker images
	@$(DOCKER_COMP) build --pull --no-cache

rebuild: ## Builds the Docker php image again
	@$(DOCKER_COMP) build php

up: ## Start the docker hub in detached mode (no logs)
	@$(DOCKER_COMP) up --detach

install: build up ## Build and start the containers

down: ## Stop the docker hub
	@$(DOCKER_COMP) down --remove-orphans

logs: ## Show live logs
	@$(DOCKER_COMP) logs --tail=0 --follow

sh: ## Connect to the PHP FPM container
	@$(PHP_CONT) sh

.PHONY = fix-perms
fix-perms: ## Fix permissions
    ifeq ($(detected_OS),Linux)
		@$(DOCKER_COMP) run --rm php chown -R $$(id -u):$$(id -g) .
    endif

.PHONY = setup
setup: website modules rebuild up fix-perms ## Configure project
	@echo "Ya puedes acceder al servidor en la siguiente dirección: https://localhost"

.PHONY = mrproper
mrproper: ## Remove containers, images and volumes (DESTRUCTIVE ACTION!!!)
	@$(DOCKER_COMP) down -v --remove-orphans --rmi local

## —— Composer 🧙 ——————————————————————————————————————————————————————————————
composer: ## Run composer, pass the parameter "c=" to run a given command, example: make composer c='req symfony/orm-pack'
	@$(eval c ?=)
	@$(COMPOSER) $(c)

vendor: ## Install vendors according to the current composer.lock file
vendor: c=install --prefer-dist --no-dev --no-progress --no-scripts --no-interaction
vendor: composer

## —— Node ———————————————————————————————————————————————————————————————
.PHONY = npm
npm: ## Run node, pass the parameter "c=" to run a given command, example: make composer c='install'
	@$(eval c ?=)
	@$(NPM) $(c)

.PHONY = modules
modules: ## Install node modules according to the current package-lock.json file
modules: c=install
modules: npm

## —— Symfony 🎵 ———————————————————————————————————————————————————————————————
sf: ## List all Symfony commands or pass the parameter "c=" to run a given command, example: make sf c=about
	@$(eval c ?=)
	@$(SYMFONY) $(c)

cc: c=c:c ## Clear the cache
cc: sf

.PHONY = website
website: c=require webapp ## Install website dependencies
website: composer

