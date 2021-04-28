<img width="180" align="right" src="https://mlsploit.github.io/static/img/mlsploit-logo.png">

# MLsploit Dockerized System

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://azuredeploy.net/)

## Requirements

This repository requires the following packages to be installed on the system:
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)


## Cloning this repository

Since this repository contains submodules of other MLsploit repositories,
we need to use the `--recursive` flag while cloning this repository.

```
$ git clone --recursive https://github.com/mlsploit/mlsploit-system.git
```


## Setting up MLsploit Docker images

The following commands will setup the respective MLsploit docker images
along with the required secret keys automatically.

```
$ cd mlsploit-system
$ ./docker-setup-system.sh
```


## Running MLsploit

This will spin up the MLsploit services and run the user interface on port 80
in the background.

```
docker-compose up -d
```


## Deploying MLsploit

This command will install all dependencies
and deploy the end-to-end MLsploit system (for Ubuntu 18.04).

```
curl -sSL https://raw.githubusercontent.com/mlsploit/mlsploit-system/master/deployment.sh | bash
```
