terraform {
  backend "s3" {
    bucket  = "markosz-jenkins-terraform-state"
    key     = "projektek/jenkins-bastion/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

# --- DINAMIKUS AMI KERESÉS (Ezüstgolyó a hiba ellen) ---
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-202*-kernel-6.1-x86_64"]
  }
}

# SSH kulcspár regisztrálása
resource "aws_key_pair" "jenkins_key" {
  key_name   = "jenkins-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDbNJKViPi2a0rjK+9Bdplai4rRZpB5b6YxWXHCUOIWyYAq6ur5cNSIxcsPaIYAVT2xMwbrNc67edEbcqyzswykUgjUu3WgZIV0/XvAmPXViti7mnWv6iz15+e7MQmou8eiUF9W79Hjc+BzBORIHUBs4TouFr4zBliPuTu/ArlrpylDSnl/Q1kDrpwStHbdue1ozGVZy5rjVnMAvlkOGXdwab9Lqw2LGsV50IBtjYSQtgU+MGWL1qSLwPwI0QGQVT3YYGxHqrAz2G1H0/KiBTeNYAQrmRPiZ0sNZ78uie6+LatjBDnbpKYzYJ2lNarLsp+xXDP3Nolt8w1h+cEs32q3MZBkewUvZMO6yV4Gy8dZvEWjaN0BJkNLVBaYFg6rOsusP0K4s7ObkHdYNSL76Msv+d0AwIA9iLKhvy4n4IFY4wwgG45Fz83VIFEKHBefDXj8hfCBYiZsbpa8UL7oFNn+nbxxkvmI8oEuk0OA8Bld+/5TZ0L4198evHL/Rx3pa/xBxpzQintKtq3Akma4Ht1/W9/dXYRX8t9qkccnN4uYHuKPA4aATKIWIoQSx0iE9vn35UaIaA1wBo64O2DubsXkc5rHAlDTiaPORlWe8c1eQN6ya3fPXr0LQPZg4uTPgldwXyimfIP5Y9SPEqsAzwQUFE+M3YeF5O3F0mPv1O0yFQ== markosz@MacBook-Pro.local" 
}

# VPC
resource "aws_vpc" "elso_halozatom" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "Jenkins-Bastion-VPC" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.elso_halozatom.id
}

# Alhálózatok
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.elso_halozatom.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = { Name = "Public-Subnet-Bastion" }
}
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.elso_halozatom.id
  cidr_block              = "10.0.4.0/24"   # Ügyelj, hogy ez a tartomány szabad legyen
  availability_zone       = "eu-central-1b" # Ez a lényeg: a másik zóna!
  map_public_ip_on_launch = true
  tags = { Name = "Public-Subnet-2"}
}
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.elso_halozatom.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-central-1a"
  tags = { Name = "Private-Subnet-1" }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.elso_halozatom.id
  cidr_block        = "10.0.3.0/24" # Új tartomány
  availability_zone = "eu-central-1b" # MÁSODIK zóna (pl. 1b)

  tags = { Name = "Private-Subnet-2" }
}

# Route Table
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.elso_halozatom.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.pub_rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}
# Security Groups
resource "aws_security_group" "bastion_sg" {
  name   = "bastion_access"
  vpc_id = aws_vpc.elso_halozatom.id
  ingress {
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

resource "aws_security_group" "web_sg" {
  name   = "web_server_access"
  vpc_id = aws_vpc.elso_halozatom.id
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
  ingress {
    from_port   = 80
    to_port     = 80
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

# Szerverek - Most már dinamikus AMI-val!
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = aws_key_pair.jenkins_key.key_name
  tags = { Name = "Bastion-Host" }
}

# Mivel most már publikus alhálózatban van, lekérhetjük a publikus IP-jét is a böngészőhöz

output "bastion_ip" { value = aws_instance.bastion.public_ip }
