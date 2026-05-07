# TP3 - Infonuagique : Déploiement d’une infrastructure multi-service sur AWS (Docker)

**Prénom & Nom :** Haroune Belhachani  
**Matricule :** 2471001  

---

## Partie I : Conception (local + GitHub)

**Lien du dépôt GitHub :** https://github.com/Haroune07/TP3-2471001

### Explication du fichier `compose.yaml`

**1. Description des services :**
- **Traefik :** Le reverse proxy qui gère le routage HTTP/HTTPS et la création des certificats SSL/TLS automatiques via Let's Encrypt.
- **DuckDNS :** Un conteneur qui s'assure de mettre à jour périodiquement l'adresse IP publique de l'instance AWS vers le nom de domaine `2471001-tp3.duckdns.org`.
- **Portainer :** Interface web d'administration pour gérer et monitorer graphiquement les conteneurs Docker (Service obligatoire).
- **NextCloud :** Solution cloud d'hébergement de fichiers et de collaboration en ligne.
- **Paperless-ngx :** Service d'archivage et de gestion de documents numérisés. Il dépend de `paperless-db` (PostgreSQL) et `paperless-redis`.
- **Luanti :** Serveur de jeu en réseau (Minetest) tournant sur le port UDP 30000.

**2. Rôle de Traefik :**
Traefik agit comme un routeur (reverse proxy) frontal. Il écoute sur les ports 80 (HTTP) et 443 (HTTPS). Son rôle est d'intercepter toutes les requêtes web entrantes et de les rediriger intelligemment vers le bon conteneur (Nextcloud, Paperless ou Portainer) en lisant le sous-domaine demandé dans l'en-tête HTTP. Il gère également automatiquement la négociation et le renouvellement des certificats de sécurité avec Let's Encrypt.

**3. Organisation générale :**
- **Réseau :** Tous les services web sont placés dans un réseau virtuel Docker nommé `proxy`. Cela permet à Traefik de communiquer avec eux de manière sécurisée et isolée. Luanti n'utilise pas ce réseau web car il expose directement son port UDP à l'hôte.
- **Volumes :** Des volumes locaux (dans le dossier `./data/`) sont liés aux conteneurs pour assurer la persistance des données (fichiers Nextcloud, base de données Postgres, certificats Let's Encrypt dans `acme.json`, configurations Portainer et Luanti). Ainsi, même si un conteneur est détruit, aucune donnée n'est perdue.
- **Variables d'environnement :** Les mots de passe, tokens et noms de domaine ne sont pas écrits "en dur" dans le fichier `compose.yaml`. Ils sont externalisés dans un fichier caché `.env` (documenté par le fichier fourni `.env.example`) qui est lu au démarrage, garantissant ainsi la sécurité des secrets.

---

## Partie II : Déploiement sur AWS

### 4. Instance EC2 - Méthode de création et configuration

L'infrastructure a été entièrement provisionnée selon le paradigme de l'Infrastructure-as-Code (IaC) à l'aide de **Terraform**. 
La configuration inclut la création d'un VPC complet, de sous-réseaux (public/privé), d'une passerelle internet (IGW), d'une table de routage et d'un groupe de sécurité.

Pour la configuration de l'instance EC2 (type `t2.large`), un script **`user-data` a été injecté automatiquement** au lancement de la machine. Ce script effectue les actions suivantes de manière totalement autonome sans aucune intervention humaine (Bonus automatisation) :
- Mise à jour des paquets du système (apt).
- Installation complète de Docker Engine et du plugin Docker Compose.
- Ajout de l'utilisateur `ubuntu` au groupe docker.
- Clonage du dépôt GitHub contenant le projet.
- Création du fichier `.env` de base à partir du `.env.example`.

*(Note : J'ai ensuite manuellement mis à jour mes identifiants secrets DuckDNS et mots de passe dans le fichier `.env` via SSH, puis lancé `sudo docker compose up -d` pour initier les services).*

**Script `user-data` utilisé (Automatisé via Terraform) :**
```bash
#!/bin/bash
# Mise à jour et installation des prérequis
apt-get update -y
apt-get install -y ca-certificates curl gnupg git

# Ajout de la clé GPG officielle de Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Ajout du dépôt Docker aux sources APT
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Installation de Docker et Docker Compose
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Ajout de l'utilisateur ubuntu au groupe docker
usermod -aG docker ubuntu

# Préparation du projet depuis GitHub
cd /home/ubuntu
git clone https://github.com/Haroune07/TP3-2471001.git
cd TP3-2471001
cp .env.example .env
chown -R ubuntu:ubuntu /home/ubuntu/TP3-2471001
```

---

### Captures d'écran AWS et Services 
*(Les captures demandées dans la grille de correction se trouvent ci-dessous ou dans les fichiers joints).*

**Réseau et Sécurité AWS :**
- Capture 1 : VPC - Mappage des ressources
- Capture 2 : Sous-réseau public (`tp3-2471001-public-1`) - Détails
- Capture 3 : Sous-réseau privé (`tp3-2471001-private-1`) - Détails
- Capture 4 : Groupe de sécurité - Règles entrantes et sortantes

**Instance EC2 :**
- Capture 5 : Détails de l'instance (IP: `100.55.71.183`, AMI: `ami-05cf1e9f73fbad2e2`, Type: `t2.large`)
- Capture 6 : Sécurité de l'instance

**Services et Docker :**
- Capture 7 : Nom de domaine DuckDNS (`2471001-tp3` pointant vers `100.55.71.183`)
- Capture 8 : Terminal SSH (Résultat de `sudo docker ps`)
- Capture 9 : Navigateur web - NextCloud (Certificat HTTPS valide)
- Capture 10 : Navigateur web - Paperless-ngx (Certificat HTTPS valide)
- Capture 11 : Navigateur web - Portainer (Certificat HTTPS valide)
- Capture 12 : Serveur de jeu Luanti (Connexion réussie au serveur)
