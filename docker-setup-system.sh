#!/usr/bin/env bash

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null && pwd -P)"

function log() {
    echo -e "\033[34m\033[1m[docker-setup-system]\033[0m $@"
}

log "Setting up MLsploit REST API..."
cd mlsploit-rest-api
./docker-setup-api.sh -ap
API_ADMIN_TOKEN=$(./docker-manage-api.sh drf_create_token admin | cut -d " " -f 3)
cd ..

cd mlsploit-execution-backend
log "Setting up MLsploit Execution Backend..."
./env-set-token.sh "$API_ADMIN_TOKEN"
./docker-setup-execution.sh
cd ..

cd mlsploit-web-ui
log "Setting up MLsploit Web UI..."
./docker-setup-ui.sh
cd ..

log "Consolidating services..."
docker-compose build > /dev/null

log "Done!"
