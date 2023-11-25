#!/usr/bin/env bash

##
## Deploy Docker and Launch Observeasy docker-compose on a Linux host
##


## create directory for obv installation
mkdir -p obv
cd obv


## install docker on this host
echo "Docker will be installed on this host"

echo "Downloading the docker install script"
curl -fsSL https://get.docker.com -o get-docker.sh

echo "Running the docker install script"
sh get-docker.sh



## install docker-compose on this host
echo "Docker-compose will be installed"

echo "Downloading docker-compose package"
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$ARCH" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose


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


