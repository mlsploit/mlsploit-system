#!/usr/bin/env bash

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null && pwd -P)"

function log() {
    echo -e "\033[34m\033[1m[deployment]\033[0m $@"
}


log "Installing system dependencies..."
sudo apt-get update -y
sudo apt-get install -y \
    git \
    curl \
    gnupg-agent \
    ca-certificates \
    apt-transport-https \
    software-properties-common


log "Setting up Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io


log "Setting up Docker Compose.."
sudo curl -L \
    "https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose


log "Setting MLsploit system..."
git clone --recursive https://github.com/mlsploit/mlsploit-system.git

cd mlsploit-system
sudo ./docker-setup-system.sh


log "Starting MLsploit services in detached mode..."
sudo docker-compose up -d