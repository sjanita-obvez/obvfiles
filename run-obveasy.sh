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
  observeasy-database:
    hostname: observeasy-database
    container_name: observeasy-database
    image: 'postgres:16-alpine'
    restart: unless-stopped
    volumes:
      - ./database/observeasy.sql:/docker-entrypoint-initdb.d/init.sql
      - ./database/database-data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: observeasy
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: observeasy
    networks:
      - observeasy

  observeasy-autoflow:
    hostname: observeasy-autoflow
    container_name: observeasy-autoflow
    image: 'interactor/api-interactor:3.1.5'
    restart: unless-stopped
    stdin_open: true
    tty: true
    ports:
      - 4000:4000
      - 9090:9090
      - 9091:9091
    volumes:
      - ./autoflow/autoflow-data:/app/data
      - ./autoflow/config.json:/app/data/config.json
    environment:
      AUTOFLOW_UI_PORT: 4000
      AUTOFLOW_BOOT_FILE: data/config.json
      AUTOFLOW_ADMIN_USERNAME: admin
      AUTOFLOW_ADMIN_PASSWORD: observeasy
      AUTOFLOW_LICENSE_FILE: # TODO: Need to update with jrc autoflow license
      DATABASE_HOST: observeasy-database
      DATABASE_NAME: observeasy
      DATABASE_USER: postgres
      DATABASE_PASSWORD: observeasy
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
    image: 'dnwo05/observeasy-dockerized:latest' # TODO: Need to update with jrc docker account
    restart: unless-stopped
    ports:
      - '80:80'
    depends_on:
      - observeasy-database
      - observeasy-autoflow


networks:
  observeasy:

volumes:
  autoflow:

EOF


## up the docker-compose
echo "Deploying Observeasy"
hash -r
sudo docker-compose up --detach --force-recreate --remove-orphans