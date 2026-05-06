terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# DA = 2471001
# 4e et 5e chiffre = 10

# 1. Réseau (VPC)
resource "aws_vpc" "tp3_vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "tp3-2471001-vpc"
  }
}

# 4. Passerelle Internet
resource "aws_internet_gateway" "tp3_igw" {
  vpc_id = aws_vpc.tp3_vpc.id

  tags = {
    Name = "tp3-2471001-igw"
  }
}

# 2.1. Sous-réseau public
resource "aws_subnet" "tp3_public" {
  vpc_id                  = aws_vpc.tp3_vpc.id
  cidr_block              = "10.10.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "tp3-2471001-public-1"
  }
}

# 2.2. Sous-réseau privé
resource "aws_subnet" "tp3_private" {
  vpc_id            = aws_vpc.tp3_vpc.id
  cidr_block        = "10.10.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "tp3-2471001-private-1"
  }
}

# 3. Tables de routage
resource "aws_route_table" "tp3_public_rtb" {
  vpc_id = aws_vpc.tp3_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tp3_igw.id
  }

  tags = {
    Name = "rtb-tp3-public"
  }
}

resource "aws_route_table" "tp3_private_rtb" {
  vpc_id = aws_vpc.tp3_vpc.id

  tags = {
    Name = "rtb-tp3-private"
  }
}

# Associations des tables de routage
resource "aws_route_table_association" "tp3_public_assoc" {
  subnet_id      = aws_subnet.tp3_public.id
  route_table_id = aws_route_table.tp3_public_rtb.id
}

resource "aws_route_table_association" "tp3_private_assoc" {
  subnet_id      = aws_subnet.tp3_private.id
  route_table_id = aws_route_table.tp3_private_rtb.id
}

# 5. Groupe de sécurité
resource "aws_security_group" "tp3_sg" {
  name        = "tp3-2471001-sg"
  description = "Autoriser SSH, HTTP, HTTPS et Luanti"
  vpc_id      = aws_vpc.tp3_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Luanti (UDP)"
    from_port   = 30000
    to_port     = 30000
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tp3-2471001-sg"
  }
}

# AMI Ubuntu 24.04
data "aws_ami" "ubuntu_24_04" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Clé SSH
resource "aws_key_pair" "deployer" {
  key_name   = "tp3-deployer-key"
  public_key = var.public_key
}

# 6. Instance EC2
resource "aws_instance" "tp3_server" {
  ami           = data.aws_ami.ubuntu_24_04.id
  instance_type = "t2.large"
  key_name      = aws_key_pair.deployer.key_name

  subnet_id              = aws_subnet.tp3_public.id
  vpc_security_group_ids = [aws_security_group.tp3_sg.id]

  # 7. Déploiement automatisé (Bonus: Script user-data automatisé)
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y ca-certificates curl gnupg git
              
              # Installation de Docker
              install -m 0755 -d /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              chmod a+r /etc/apt/keyrings/docker.gpg

              echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
                $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
                tee /etc/apt/sources.list.d/docker.list > /dev/null

              apt-get update
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

              # Ajout de l'utilisateur ubuntu au groupe docker
              usermod -aG docker ubuntu

              # Clonage du dépôt et préparation
              cd /home/ubuntu
              # Remplacez l'URL par l'URL publique de votre dépôt GitHub réel
              git clone https://github.com/votre-compte/tp3-2471001.git tp3
              cd tp3
              chown -R ubuntu:ubuntu /home/ubuntu/tp3
              
              # Création du fichier .env à partir du template (l'étudiant devra éditer avec ses tokens)
              cp .env.example .env
              chown ubuntu:ubuntu .env
              
              # docker compose up -d sera exécuté manuellement par l'étudiant après l'édition de .env
              EOF

  tags = {
    Name = "tp3-2471001-multi-service"
  }
}
