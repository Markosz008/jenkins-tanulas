terraform {
  # Távoli állapottárolás S3-ban
  backend "s3" {
    bucket         = "markosz-jenkins-terraform-state"
    key            = "projektek/jenkins-vpc/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
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

# 1. A hálózat (VPC)
resource "aws_vpc" "elso_halozatom" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Jenkins-VPC-Projekt"
  }
}

# 2. Alhálózat (Subnet) az EC2-nek
resource "aws_subnet" "elso_alhalozat" {
  vpc_id                  = aws_vpc.elso_halozatom.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # Hogy elérjük kívülről SSH-n
  tags = {
    Name = "Ansible-Subnet"
  }
}

# 3. Biztonsági csoport (Security Group / Tűzfal)
resource "aws_security_group" "jenkins_access" {
  name        = "jenkins_access"
  description = "SSH eleres engedelyezese"
  vpc_id      = aws_vpc.elso_halozatom.id

  # SSH bemenet
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Minden kimenő forgalom engedélyezése
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. Az EC2 Szerver (A celpont az Ansible-nek)
resource "aws_instance" "web_szerver" {
  ami                    = "ami-0de02246788e4a350" # Amazon Linux 2023 (Frankfurt)
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.elso_alhalozat.id
  vpc_security_group_ids = [aws_security_group.jenkins_access.id]

  tags = {
    Name = "Ansible-Target-Server"
  }
}
