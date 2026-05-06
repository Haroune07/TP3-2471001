# TP3 - Déploiement d'une infrastructure multi-service sur AWS

## Description

Ce dépôt contient les fichiers nécessaires au déploiement d'une infrastructure multi-service avec Docker et Docker Compose. L'infrastructure est hébergée sur une instance AWS EC2 et accessible via un reverse proxy Traefik, avec des certificats HTTPS gérés automatiquement par Let's Encrypt et un nom de domaine DuckDNS.

## Services inclus

1. **Traefik** : Reverse proxy et gestionnaire SSL/TLS.
2. **Portainer** : Interface de gestion Docker.
3. **NextCloud** : Plateforme d'hébergement de fichiers et travail collaboratif.
4. **Paperless-ngx** : Système de gestion et d'archivage de documents (avec base de données PostgreSQL et Redis).
5. **Luanti** : Serveur de jeu (anciennement Minetest), exposé sur le port UDP 30000.

## Prérequis

- Une instance AWS EC2 (Ubuntu 24.04 LTS, type t2.large recommandé)
- Un nom de domaine configuré sur DuckDNS
- Docker et Docker Compose installés sur l'instance

## Instructions de déploiement

1. Clonez ce dépôt sur votre instance EC2 :
   ```bash
   git clone <URL_DU_DEPOT> tp3
   cd tp3
   ```

2. Créez un fichier `.env` basé sur le modèle `.env.example` et remplissez vos informations :
   ```bash
   cp .env.example .env
   nano .env
   ```
   *Assurez-vous de renseigner correctement `ACME_EMAIL`, `DOMAIN`, et les variables pour Paperless.*

3. Démarrez l'infrastructure avec Docker Compose :
   ```bash
   docker compose up -d
   ```

4. Accédez à vos services via votre domaine DuckDNS (ex: `https://portainer.votre-domaine.duckdns.org`). Pour Luanti, connectez-vous directement sur l'IP de votre serveur ou le domaine sur le port 30000.
