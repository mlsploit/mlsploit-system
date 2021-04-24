SHELL := /bin/bash

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

DOCKER_COMPOSE_URL := https://github.com/docker/compose/releases/download
DOCKER_COMPOSE_URL := $(DOCKER_COMPOSE_URL)/1.25.5
DOCKER_COMPOSE_URL := $(DOCKER_COMPOSE_URL)/docker-compose-$(shell uname -s)-$(shell uname -m)

# ~~~

.PHONY: all
all: ubuntu_deps docker_compose_build

.PHONY: clean
clean:
	sudo rm -rf $(dir $(GIT_SUBMODULES)) && git submodule deinit -f .

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

/usr/bin/docker: /snap/bin/docker
/usr/bin/docker-compose: /usr/local/bin/docker-compose

/usr/bin/docker /usr/bin/docker-compose:
	sudo ln -s $< $@

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

.DELETE_ON_ERROR: $(MLSPLOIT_SETUP_DIR)/mlsploit-rest-api
$(MLSPLOIT_SETUP_DIR)/mlsploit-rest-api: mlsploit-rest-api/modules.csv | $(MODULE_PREREQUISITES)
	cd $(@F) && sudo ./docker-setup-api.sh -apt | tee $@; test $${PIPESTATUS[0]} -eq 0

mlsploit-rest-api/.admintoken: $(MLSPLOIT_SETUP_DIR)/mlsploit-rest-api
	cd $(@D) && sudo ./docker-manage-api.sh drf_create_token admin | cut -d " " -f 3 > $(@F)

# ~~~

BACKEND_PREREQUISITES := mlsploit-execution-backend/.env mlsploit-execution-backend/modules.csv

mlsploit-execution-backend/.env: mlsploit-rest-api/.admintoken | mlsploit-execution-backend/.git
	API_ADMIN_TOKEN=$$(cat $<) && cd $(@D) && ./env-set-token.sh "$${API_ADMIN_TOKEN}"

mlsploit-execution-backend/modules.csv: | mlsploit-execution-backend/.git
	cp modules.csv.example $@

.DELETE_ON_ERROR: $(MLSPLOIT_SETUP_DIR)/mlsploit-execution-backend
$(MLSPLOIT_SETUP_DIR)/mlsploit-execution-backend: $(BACKEND_PREREQUISITES) | $(MODULE_PREREQUISITES)
	cd $(@F) && sudo ./docker-setup-execution.sh | tee $@; test $${PIPESTATUS[0]} -eq 0

# ~~~

.DELETE_ON_ERROR: $(MLSPLOIT_SETUP_DIR)/mlsploit-web-ui
$(MLSPLOIT_SETUP_DIR)/mlsploit-web-ui: | mlsploit-web-ui/.git $(MODULE_PREREQUISITES)
	cd $(@F) && sudo ./docker-setup-ui.sh | tee $@; test $${PIPESTATUS[0]} -eq 0

# ~~~

.PHONY: docker_compose_build
docker_compose_build: $(MLSPLOIT_MODULES) | /usr/bin/docker-compose
	sudo docker-compose build

.PHONY: docker_compose_up
docker_compose_up: docker_compose_build
	sudo docker-compose up -d