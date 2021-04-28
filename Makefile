SHELL := /bin/bash


ifneq ($(shell groups $(shell whoami) | grep -c "\bdocker\b"), 1)
$(error User $(shell whoami) should belong to the docker group for running recipes)
endif


MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

DONE_DIR := $(abspath $(MAKEFILE_DIR)/.done)
APT_PKG_DIR := $(DONE_DIR)/apt
MLSPLOIT_SETUP_DIR := $(DONE_DIR)/mlsploit

APT_PACKAGES :=\
	$(APT_PKG_DIR)/curl \
	$(APT_PKG_DIR)/git

MLSPLOIT_MODULE_NAMES :=\
	mlsploit-rest-api \
	mlsploit-execution-backend \
	mlsploit-web-ui

GIT_SUBMODULES := $(addsuffix /.git,$(MLSPLOIT_MODULE_NAMES))
MLSPLOIT_MODULES := $(addprefix $(MLSPLOIT_SETUP_DIR)/,$(MLSPLOIT_MODULE_NAMES))
MODULE_PREREQUISITES := /usr/bin/docker-compose $(MLSPLOIT_SETUP_DIR)

DOCKER_COMPOSE_RELEASE := https://github.com/docker/compose/releases/download
DOCKER_COMPOSE_VERSION := 1.25.5/docker-compose-$(shell uname -s)-$(shell uname -m)
DOCKER_COMPOSE_URL := $(DOCKER_COMPOSE_RELEASE)/$(DOCKER_COMPOSE_VERSION)

# ~~~

.PHONY: all
all: ubuntu_deps docker_compose_build

.PHONY: clean
clean:
	sudo rm -rf $(dir $(GIT_SUBMODULES)) && git submodule deinit -f .
	rm -rf $(MLSPLOIT_SETUP_DIR)

.PHONY: ubuntu_deps
ubuntu_deps: $(APT_PACKAGES) /usr/bin/docker-compose

$(APT_PKG_DIR) $(MLSPLOIT_SETUP_DIR):
	mkdir -p $@

# ~~~

.DELETE_ON_ERROR: $(APT_PACKAGES)
$(APT_PACKAGES): | $(APT_PKG_DIR)
	sudo apt-get update -y
	sudo apt-get install -y $(@F) | tee $@; test $${PIPESTATUS[0]} -eq 0

# ~~~

/usr/bin/docker: | /snap/bin/docker
/usr/bin/docker-compose: | /usr/local/bin/docker-compose

/usr/bin/docker /usr/bin/docker-compose:
	sudo ln -s $| $@

/snap/bin/docker:
	sudo snap install docker
	@echo "Waiting 30s for docker to start..." && sleep 30

/usr/local/bin/docker-compose: | /usr/bin/docker
	sudo curl -L $(DOCKER_COMPOSE_URL) -o $@
	sudo chmod +x $@

# ~~~

$(GIT_SUBMODULES): | $(APT_PKG_DIR)/git
	git submodule update --init `dirname $@`

.PHONY: git_submodules
git_submodules: $(GIT_SUBMODULES)

# ~~~

mlsploit-rest-api/modules.csv: | mlsploit-rest-api/.git
	cp modules.csv.example $@

mlsploit-rest-api/.env: | mlsploit-rest-api/.git
	cp $(@D)/.env.example $@

.DELETE_ON_ERROR: $(MLSPLOIT_SETUP_DIR)/mlsploit-rest-api
$(MLSPLOIT_SETUP_DIR)/mlsploit-rest-api: mlsploit-rest-api/modules.csv | $(MODULE_PREREQUISITES)
	cd $(@F) && ./docker-setup-api.sh -apt | tee $@; test $${PIPESTATUS[0]} -eq 0

mlsploit-rest-api/.admintoken: $(MLSPLOIT_SETUP_DIR)/mlsploit-rest-api
	cd $(@D) && ./docker-manage-api.sh drf_create_token admin | cut -d " " -f 3 > $(@F)

# ~~~

BACKEND_PREREQUISITES := mlsploit-execution-backend/.env mlsploit-execution-backend/modules.csv

mlsploit-execution-backend/.env: mlsploit-rest-api/.admintoken | mlsploit-execution-backend/.git
	API_ADMIN_TOKEN=$$(cat $<) && cd $(@D) && ./env-set-token.sh "$${API_ADMIN_TOKEN}"

mlsploit-execution-backend/modules.csv: | mlsploit-execution-backend/.git
	cp modules.csv.example $@

.DELETE_ON_ERROR: $(MLSPLOIT_SETUP_DIR)/mlsploit-execution-backend
$(MLSPLOIT_SETUP_DIR)/mlsploit-execution-backend: $(BACKEND_PREREQUISITES) | $(MODULE_PREREQUISITES)
	cd $(@F) && ./docker-setup-execution.sh | tee $@; test $${PIPESTATUS[0]} -eq 0

# ~~~

.DELETE_ON_ERROR: $(MLSPLOIT_SETUP_DIR)/mlsploit-web-ui
$(MLSPLOIT_SETUP_DIR)/mlsploit-web-ui: | mlsploit-web-ui/.git $(MODULE_PREREQUISITES)
	cd $(@F) && ./docker-setup-ui.sh | tee $@; test $${PIPESTATUS[0]} -eq 0

# ~~~

.PHONY: docker_compose_build
docker_compose_build: $(MLSPLOIT_MODULES) | /usr/bin/docker-compose
	docker-compose build

.PHONY: docker_compose_up
docker_compose_up: docker_compose_build
	docker-compose up -d

.PHONY: docker_compose_logs
docker_compose_logs:
	docker-compose logs -f

.PHONY: docker_compose_down
docker_compose_down:
	docker-compose down

# ~~~

.PHONY: docker_hosting_certbot
docker_hosting_certbot:
	docker-compose exec hosting certbot --apache $(ARGS)

.PHONY: docker_api_enable_ssl
docker_api_enable_ssl: mlsploit-rest-api/.env
	LINENUM=$$(grep -nm 1 "^MLSPLOIT_HOSTING_SSL_ENABLED=" $< | cut -f1 -d:) \
		&& (sed "$${LINENUM}s/.*/MLSPLOIT_HOSTING_SSL_ENABLED=true/" $< > $<.tmp) && mv $<.tmp $<
