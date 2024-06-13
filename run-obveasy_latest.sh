#!/usr/bin/env bash

##
## Deploy Docker and Launch Observeasy docker-compose on a Linux host
##


## create directory for obv installation
mkdir -p obv2
cd obv2


# Check if the Docker daemon is running
if [[ "$(systemctl is-active docker)" == "active" ]]; then
  echo "Docker is running, moving on to create and deploy the docker compose file"

else
  echo "Docker is not running, Docker will be installed on this host"
## install docker on this host
  echo "Download the docker install script"
  curl -fsSL https://get.docker.com -o get-docker.sh

  echo "Running the docker install script"
  sh get-docker.sh
fi

## install docker-compose on this host
echo "Docker-compose will be installed"

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
version: "3"

services:
  # ===================
  # Observeasy Services
  # ===================
  observeasy-database:
    hostname: observeasy-database
    container_name: observeasy-database
    image: observeasypulzze/observeasy-database:latest
    restart: unless-stopped
    volumes:
      - observeasy-database:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: observeasy
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: observeasy
    networks:
      - observeasy

  observeasy-autoflow:
    hostname: observeasy-autoflow
    container_name: observeasy-autoflow
    image: observeasypulzze/observeasy-autoflow:latest
    restart: unless-stopped
    stdin_open: true
    tty: true
    ports:
      - 4000:4000
      - 8090:8090
      - 8091:8091
      - 8092:8092
      - 9090:9090
      - 9091:9091
      - 9092:9092
    volumes:
      - observeasy-autoflow:/app/data
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

  observeasy-autoflow-cron:
    hostname: observeasy-autoflow-cron
    container_name: observeasy-autoflow-cron
    image: observeasypulzze/observeasy-cron:latest
    stdin_open: true
    tty: true
    depends_on:
      - observeasy-autoflow
    networks:
      - observeasy

  observeasy-frontend:
    hostname: observeasy-frontend
    container_name: observeasy-frontend
    image: observeasypulzze/observeasy-frontend:latest # TODO: Need to update with jrc docker account
    restart: unless-stopped
    ports:
      - '80:80'
      - '443:443'
    depends_on:
      - observeasy-database
      - observeasy-autoflow

  # ================
  # phpIPAM Services
  # ================
  phpipam-web:
    hostname: phpipam-web
    container_name: phpipam-web
    image: phpipam/phpipam-www:latest
    ports:
      - "9080:80"
    environment:
      TZ: America/Los_Angeles
      IPAM_DATABASE_HOST: phpipam-mariadb
      IPAM_DATABASE_USER: root
      IPAM_DATABASE_PASS: observeasy
      IPAM_DATABASE_NAME: phpipam
    restart: unless-stopped
#    volumes:
#      - phpipam-logo:/phpipam/css/images/logo
#      - phpipam-ca:/usr/local/share/ca-certificates:ro
#      - ./phpipam/config.dist.php:/phpipam/config.dist.php
    depends_on:
      - phpipam-mariadb
    networks:
      - observeasy

  phpipam-cron:
    hostname: phpipam-cron
    container_name: phpipam-cron
    image: phpipam/phpipam-cron:latest
    environment:
      TZ: Europe/London
      IPAM_DATABASE_HOST: phpipam-mariadb
      IPAM_DATABASE_USER: root
      IPAM_DATABASE_PASS: observeasy
      SCAN_INTERVAL: 1h
    restart: unless-stopped
    volumes:
      - phpipam-ca:/usr/local/share/ca-certificates:ro
    depends_on:
      - phpipam-mariadb
    networks:
      - observeasy

  phpipam-mariadb:
    hostname: phpipam-mariadb
    container_name: phpipam-mariadb
    image: mariadb:latest
    environment:
      MYSQL_DATABASE: phpipam
      MYSQL_ROOT_PASSWORD: observeasy
    restart: unless-stopped
#    volumes:
#      - ./phpipam/phpipam.sql:/docker-entrypoint-initdb.d/init.sql
#      - ./phpipam/phpipam-database-data:/var/lib/mysql
    networks:
      - observeasy

networks:
  observeasy:

volumes:
  observeasy-autoflow:
  observeasy-database:
#  phpipam-logo:
#  phpipam-ca:

EOF


## up the docker-compose
echo "Deploying Observeasy"
hash -r
sudo docker-compose up --detach --force-recreate --remove-orphans
