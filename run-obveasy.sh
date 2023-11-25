#!/usr/bin/env bash

##
## Deploy Docker and Launch Observeasy docker-compose on a Linux host
##


## prepare working directory
mkdir -p obv
cd obv


## test and install docker
if ! command -v docker &> /dev/null
then
    echo "Docker will be installed on this host"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
fi


## test and install docker-compose
if ! command -v docker-compose &> /dev/null
then
    echo "Docker-compose will be installed"
    ARCH=$(uname -m)
    if [ "$ARCH" = "armv7l" ]; then
        ARCH="armv7"
    fi
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$ARCH" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
fi


## create the docker compose yaml file
echo "Creating the docker compose file"
cat << EOF > docker-compose.yml
version: '3'

services:
  # ===================
  # Observeasy Services
  # ===================


EOF


## up the docker-compose
echo "Deploying Observeasy"
hash -r
sudo docker-compose up --detach --force-recreate --remove-orphans
