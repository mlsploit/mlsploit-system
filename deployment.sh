#!/usr/bin/env bash

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null && pwd -P)"

sudo apt-get update -y
sudo apt-get install -y make
sudo addgroup docker
sudo adduser $USER docker

if [[ ! -d mlsploit-system ]]; then
    git clone https://github.com/mlsploit/mlsploit-system.git
fi

cd mlsploit-system
newgrp docker << EOF
make docker_compose_up
EOF