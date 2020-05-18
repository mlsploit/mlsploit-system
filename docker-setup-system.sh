#!/usr/bin/env bash

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null && pwd -P)"

function log() {
    echo -e "\033[34m\033[1m[docker-setup-system]\033[0m $@"
}

function usage() {
    echo "usage: bash docker-setup-system.sh [-mh]"
    echo
    echo "options:"
    echo "    m    Set up in manual mode."
    echo "    h    Show this message."
    echo
    echo "This is a helper script to set up the MLsploit system."
}

MANUAL_MODE="false"
while getopts ":apth" OPTKEY; do
    case $OPTKEY in
        m )
            MANUAL_MODE="true"
            ;;
        h )
            usage
            exit 0
            ;;
        \? )
            echo "invalid option: -$OPTARG" 1>&2
            echo
            usage
            exit 1
            ;;
    esac
done

log "Setting up MLsploit REST API..."
cd mlsploit-rest-api
if [[ $MANUAL_MODE == "true" ]]; then
    ./docker-setup-api.sh -p
else
    if [[ ! -f modules.csv ]]; then
        cp ../modules.csv.example modules.csv
    fi
    ./docker-setup-api.sh -apt
fi

API_ADMIN_TOKEN=$(./docker-manage-api.sh drf_create_token admin | cut -d " " -f 3)
cd ..

cd mlsploit-execution-backend
log "Setting up MLsploit Execution Backend..."
./env-set-token.sh "$API_ADMIN_TOKEN"
if [[ $MANUAL_MODE != "true" && ! -f modules.csv ]]; then
    cp ../modules.csv.example modules.csv
fi
./docker-setup-execution.sh
cd ..

cd mlsploit-web-ui
log "Setting up MLsploit Web UI..."
./docker-setup-ui.sh
cd ..

log "Consolidating services..."
docker-compose build > /dev/null

log "Done!"
