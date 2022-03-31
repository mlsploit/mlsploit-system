<img width="180" align="right" src="https://mlsploit.github.io/static/img/mlsploit-logo.png">

# MLsploit Dockerized System

<!-- [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://azuredeploy.net/) -->

## Requirements

This repository requires the following packages to be installed on the system:
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Quickstart: Deploying MLsploit (one-click setup)

This command will install all dependencies
and deploy the end-to-end MLsploit system (for Ubuntu 18.04).

```bash
curl -sSL https://raw.githubusercontent.com/mlsploit/mlsploit-system/master/deployment.sh | bash
```

[![Deploy To Azure](azuredeploy.svg)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmlsploit%2Fmlsploit-system%2Fmaster%2Fazuredeploy.json)

## Cloning this repository

Since this repository contains submodules of other MLsploit repositories,
we need to use the `--recursive` flag while cloning this repository.

```
$ git clone --recursive https://github.com/mlsploit/mlsploit-system.git
```


## Setting up MLsploit Docker images

The following command will setup the respective MLsploit docker images
along with the required secret keys automatically.

```bash
make docker_compose_build
```


## Running MLsploit

This will spin up the MLsploit services and run the user interface on port 80
in the background.

```bash
make docker_compose_up
```

### Production setup

To run MLsploit in production mode and allow external execution workers be able to connect to MLsploit, run:

```bash
make docker_compose_up_prod
```
