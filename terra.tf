# =====================================================================
# CONFIGURACIÓN DE PROVEEDORES
# =====================================================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# =====================================================================
# 1. GENERACIÓN AUTOMÁTICA DE CLAVES SSH (.PEM)
# =====================================================================
resource "tls_private_key" "clave_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = "clave-proyecto-4-capas"
  public_key = tls_private_key.clave_ssh.public_key_openssh
}

resource "local_file" "guardar_clave" {
  content         = tls_private_key.clave_ssh.private_key_pem
  filename        = "${path.module}/clave-4-capas.pem"
  file_permission = "0400"
}

# =====================================================================
# 2. CONFIGURACIÓN DE RED (VPC, SUBREDES Y GATEWAYS)
# =====================================================================
resource "aws_vpc" "vpc_principal" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "vpc-principal-4capas" } # <-- Asegúrate de que tenga el "="
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_principal.id
  tags   = { Name = "igw-principal" }
}

# --- SUBREDES ---
# Capa Pública (Frontend)
resource "aws_subnet" "subred_front" {
  vpc_id                  = aws_vpc.vpc_principal.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "subred-frontend-publica" }
}

# Capa Privada (Backend 1)
resource "aws_subnet" "subred_back1" {
  vpc_id            = aws_vpc.vpc_principal.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags              = { Name = "subred-backend1-privada" }
}

# Capa Privada (Backend 2)
resource "aws_subnet" "subred_back2" {
  vpc_id            = aws_vpc.vpc_principal.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags              = { Name = "subred-backend2-privada" }
}

# Capa Privada (Base de Datos)
resource "aws_subnet" "subred_datos" {
  vpc_id            = aws_vpc.vpc_principal.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1a"
  tags              = { Name = "subred-datos-privada" }
}

# --- NAT GATEWAY (Para que las capas privadas salgan a Internet de forma segura) ---
resource "aws_eip" "eip_nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.eip_nat.id
  subnet_id     = aws_subnet.subred_front.id # Debe estar en la subred pública
  tags          = { Name = "nat-gateway" }
}

# =====================================================================
# 3. TABLAS DE RUTEO (CORREGIDO)
# =====================================================================
# Ruta Pública -> Internet Gateway
resource "aws_route_table" "rt_publica" {
  vpc_id = aws_vpc.vpc_principal.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "rt-publica" }
}

resource "aws_route_table_association" "asoc_front" {
  subnet_id      = aws_subnet.subred_front.id
  route_table_id = aws_route_table.rt_publica.id # <-- Asegúrate de agregar el ".id"
}

# Ruta Privada -> NAT Gateway
resource "aws_route_table" "rt_privada" {
  vpc_id = aws_vpc.vpc_principal.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = { Name = "rt-privada" }
}

resource "aws_route_table_association" "asoc_back1" {
  subnet_id      = aws_subnet.subred_back1.id
  route_table_id = aws_route_table.rt_privada.id # <-- Asegúrate de agregar el ".id"
}

resource "aws_route_table_association" "asoc_back2" {
  subnet_id      = aws_subnet.subred_back2.id
  route_table_id = aws_route_table.rt_privada.id # <-- Asegúrate de agregar el ".id"
}

resource "aws_route_table_association" "asoc_datos" {
  subnet_id      = aws_subnet.subred_datos.id
  route_table_id = aws_route_table.rt_privada.id # <-- Asegúrate de agregar el ".id"
}

# =====================================================================
# 4. GRUPOS DE SEGURIDAD (FIREWALLS EN CADENA) - CORREGIDO
# =====================================================================

# SG Frontend: Permite HTTP, HTTPS y SSH mundial
resource "aws_security_group" "sg_frontend" {
  name        = "sg_frontend"
  description = "Acceso para el Frontend desde Internet"
  vpc_id      = aws_vpc.vpc_principal.id

  ingress {
    description = "HTTP desde Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS desde Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG Backend 1: Solo permite tráfico que venga del SG del Frontend
resource "aws_security_group" "sg_backend_1" {
  name        = "sg_backend_1"
  description = "Acceso exclusivo para el Backend 1"
  vpc_id      = aws_vpc.vpc_principal.id

ingress {
  description     = "API Ventas desde el Frontend"
  from_port       = 8080
  to_port         = 8080
  protocol        = "tcp"
  security_groups = [aws_security_group.sg_frontend.id] # Solo permite tráfico del Front
}

  ingress {
    description = "SSH interno"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG Backend 2: Solo permite tráfico que venga del SG del Frontend
resource "aws_security_group" "sg_backend_2" {
  name        = "sg_backend_2"
  description = "Acceso exclusivo para el Backend 2"
  vpc_id      = aws_vpc.vpc_principal.id

ingress {
  description     = "API Despachos desde el Frontend"
  from_port       = 8080
  to_port         = 8080
  protocol        = "tcp"
  security_groups = [aws_security_group.sg_frontend.id] # Solo permite tráfico del Front
}

  ingress {
    description = "SSH interno"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG Base de Datos: Solo permite tráfico que venga de Backend 1 o Backend 2
resource "aws_security_group" "sg_datos" {
  name        = "sg_datos"
  description = "Acceso exclusivo desde los Backends"
  vpc_id      = aws_vpc.vpc_principal.id

  ingress {
    description     = "DB desde Backend 1"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_backend_1.id]
  }

  ingress {
    description     = "DB desde Backend 2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_backend_2.id]
  }

  ingress {
    description = "SSH interno"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# =====================================================================
# 5. INSTANCIAS EC2 CON AUTOMATIZACIÓN DE DOCKER (USER_DATA)
# =====================================================================

# Variable común para simplificar el script de instalación de Docker
locals {
  docker_setup = <<-EOF
              #!/bin/bash
              yum update -y
              yum upgrade -y
              yum install docker -y
              systemctl enable docker
              systemctl start docker
              usermod -aG docker ec2-user
              yum install git -y
              
              # Instalar Docker Compose v2 de forma global
              mkdir -p /usr/local/lib/docker/cli-plugins/
              curl -SL https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
              chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
              ln -s /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
              EOF
}

# Instancia Frontend (Pública)
resource "aws_instance" "ec2_frontend" {
  ami                    = "ami-00e801948462f718a"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.subred_front.id
  vpc_security_group_ids = [aws_security_group.sg_frontend.id]
  key_name               = aws_key_pair.key_pair.key_name
  tags                   = { Name = "ec2-frontend" }
  user_data              = local.docker_setup
}

# IP Elástica fija para el Frontend
resource "aws_eip" "eip_front" {
  domain   = "vpc"
  instance = aws_instance.ec2_frontend.id
}

# Instancia Backend 1 (Privada)
resource "aws_instance" "ec2_backend_ventas" {
  ami                    = "ami-00e801948462f718a"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.subred_back1.id
  vpc_security_group_ids = [aws_security_group.sg_backend_1.id]
  key_name               = aws_key_pair.key_pair.key_name
  tags                   = { Name = "ec2-backend-1" }
  user_data              = local.docker_setup
}

# Instancia Backend 2 (Privada)
resource "aws_instance" "ec2_backend_despachos" {
  ami                    = "ami-00e801948462f718a"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.subred_back2.id
  vpc_security_group_ids = [aws_security_group.sg_backend_2.id]
  key_name               = aws_key_pair.key_pair.key_name
  tags                   = { Name = "ec2-backend-2" }
  user_data              = local.docker_setup
}

# Instancia Base de Datos (Privada)
resource "aws_instance" "ec2_datos" {
  ami                    = "ami-00e801948462f718a"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.subred_datos.id
  vpc_security_group_ids = [aws_security_group.sg_datos.id]
  key_name               = aws_key_pair.key_pair.key_name
  tags                   = { Name = "ec2-base-datos" }
  user_data              = local.docker_setup
}

# =====================================================================
# 6. ENTRADAS DE PANTALLA (OUTPUTS)
# =====================================================================
output "ip_publica_frontend" { value = aws_eip.eip_front.public_ip }
output "ip_privada_backend_1" { value = aws_instance.ec2_backend_ventas.private_ip }
output "ip_privada_backend_2" { value = aws_instance.ec2_backend_despachos.private_ip }
output "ip_privada_base_datos" { value = aws_instance.ec2_datos.private_ip }