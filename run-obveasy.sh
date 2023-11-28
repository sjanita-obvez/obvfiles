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

echo "Install docker-compose"
cpu=$(uname -m)
echo $cpu

distro=$(uname -s)
if [ "$distro" = "Linux" ]; then
    distro="linux"
fi
echo $distro
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$distro-$cpu" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose


## create variables for docker-compose file
export pg_pw=$1
export af_pw=$2


## create the docker compose yaml file
echo "Creating the docker compose file"
cat << EOF > docker-compose.yml
version: '1.1'

services:
  # ===================
  # Observeasy Services
  # ===================
  observeasy-database:
    hostname: observeasy-database
    container_name: observeasy-database
    image: pulzzedongyeon/observeasy-database:latest
    restart: unless-stopped
    volumes:
      - observeasy-database:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: observeasy
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: $pg_pw
    networks:
      - observeasy

  observeasy-autoflow:
    hostname: observeasy-autoflow
    container_name: observeasy-autoflow
    image: pulzzedongyeon/observeasy-autoflow:latest
    restart: unless-stopped
    stdin_open: true
    tty: true
    ports:
      - 4000:4000
      - 9090:9090
      - 9091:9091
    volumes:
      - observeasy-autoflow:/app/data
    environment:
      AUTOFLOW_UI_PORT: 4000
      AUTOFLOW_BOOT_FILE: data/config.json
      AUTOFLOW_ADMIN_USERNAME: admin
      AUTOFLOW_ADMIN_PASSWORD: $af_pw
      AUTOFLOW_LICENSE_FILE:
      DATABASE_HOST: observeasy-database
      DATABASE_NAME: observeasy
      DATABASE_USER: postgres
      DATABASE_PASSWORD: $pg_pw
      PHPIPAM_APP_ID: observeasy
      PHPIPAM_APP_CODE: f_T_icyLF6WR7D3jseVng9ADMbrtPGlR
      PHPIPAM_BASE_URI: phpipam-web
      PHPIPAM_USERNAME: admin
      PHPIPAM_PASSWORD: ipamadmin
    depends_on:
      - observeasy-database
    networks:
      - observeasy

  observeasy-frontend:
    hostname: observeasy-frontend
    container_name: observeasy-frontend
    image: 'dnwo05/observeasy-dockerized:latest'
    restart: unless-stopped
    ports:
      - '8080:80'
    depends_on:
      - observeasy-database
      - observeasy-autoflow


networks:
  observeasy:

volumes:
  observeasy-autoflow:
  observeasy-database:

EOF


## up the docker-compose
echo "Deploying Observeasy"
hash -r
sudo docker-compose up --detach --force-recreate --remove-orphans
