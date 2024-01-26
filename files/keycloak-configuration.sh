#!/bin/bash

# Installing docker, you can change the version below
curl -sL https://releases.rancher.com/install-docker/${docker_version}.sh | sh

# Installing docker compose
mkdir -p /root/.docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.24.1/docker-compose-linux-x86_64 -o /root/.docker/cli-plugins/docker-compose
chmod +x /root/.docker/cli-plugins/docker-compose

# Installing Snapd

sudo apt update
sudo apt install snapd ca-certificates curl gnupg

sudo snap install core
sudo snap refresh core

# Installing Certbot
sudo apt remove certbot
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot

# Request Certificate. The certificate and key are saved at  /etc/letsencrypt/live/${dns_record}
sudo certbot certonly --non-interactive --standalone -d ${dns_record} --agree-tos -m ${email}

# Server Preconfiguration

mkdir /opt/keycloak
echo "version: '3'
services:
  keycloak:
    image: quay.io/keycloak/keycloak:latest
    container_name: keycloak
    restart: always
    ports:
      - 80:8080
      - 443:8443
 
    volumes:
      - ./certs/fullchain.pem:/etc/x509/https/tls.crt
      - ./certs/privkey.pem:/etc/x509/https/tls.key
   
    environment:
      - KEYCLOAK_ADMIN=admin
      - KEYCLOAK_ADMIN_PASSWORD=${keycloak_password}
      - KC_HOSTNAME=${dns_record}
      - KC_HTTPS_CERTIFICATE_FILE=/etc/x509/https/tls.crt
      - KC_HTTPS_CERTIFICATE_KEY_FILE=/etc/x509/https/tls.key
    command:
      - start-dev" > /opt/keycloak/keycloak.yml

mkdir /opt/keycloak/certs
cp /etc/letsencrypt/live/${dns_record}/fullchain.pem /opt/keycloak/certs
cp /etc/letsencrypt/live/${dns_record}/privkey.pem /opt/keycloak/certs
chmod 755 /opt/keycloak/certs
chmod 644 /opt/keycloak/certs/*

#Starting the Keycloak Server
cd /opt/keycloak
docker compose -f keycloak.yml up

