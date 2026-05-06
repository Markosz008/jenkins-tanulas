terraform {
  # 1. Távoli állapottárolás S3-ban
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

# 2. SSH kulcspár regisztrálása az AWS-ben
resource "aws_key_pair" "jenkins_key" {
  key_name   = "jenkins-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDPN47hdfnKP9ubS6MGGpo+viXlhWsIWOfRUR72tyBhRV4gByf9y5w9IhNvijqVfvvovPu60DtFV/N3ZVrpSmmUF7iSoTshhls8fJ5LizL7Ewyip830Veg2HMpSWuqVDlUDWMhC37UxIngrxmTjQhRHQj6gXLUy33JrpbX9XAIcZJHuwnkvcJZ97Qfxl1x4sLMkhy7ZXW3t+CEPkgwdLmRDJykh263n4sMTqFR05AVm4VsNSf9iriqiwwReRd2QZpdt3e0kXSlt61/JeGIbIandTPU9vKo0XVuDk6VZSTT+Im7ndxBdE7VYczqZQrYVeIkp5WHsKVkM7HtnNNfW7sgBESZN2ZPzl85PEh2QNXQOmXgY9L2IZuUapSHjq3d4MWMNjCZADTp+CBmPZYEwvnMOx01+amamR6PqYXY+hyILzzRZpGui6E6j+6L9j8zSXeTd6lQrBvp+6vtsLB/lJFKxejDeBONbh/UdoVBcwxrUf3I8gGNHAj/h0bBGiOUAshAvt9o9zxENZy2GlGGy0gbnRMvwV59HZLyPnDTUg/2o+QkI2RyGc+WH9FpLY5ZKaQ5PXIkIdgXGfBv3FT3by+FkT7S6K/3pg8ZP7IWlGyQNs4lEWvNapQKR5mnl20xK9Kl87qfQzOflsAWBtu5lEb8EflfEoKH64tcJ6/BOdLa0BQ== root@d35f67224ea7" 
}

# 3. Hálózati réteg (VPC)
resource "aws_vpc" "elso_halozatom" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "Jenkins-Bastion-VPC" }
}

# Internet Gateway a publikus eléréshez
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.elso_halozatom.id
}

# 4. Alhálózatok (Subnets)
# Publikus alhálózat a Bastion-nak
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.elso_halozatom.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = { Name = "Public-Subnet-Bastion" }
}

# Privát alhálózat a Web szervernek
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.elso_halozatom.id
  cidr_block = "10.0.2.0/24"
  tags = { Name = "Private-Subnet-Web" }
}

# Publikus Route Table
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

# 5. Biztonsági Csoportok (Security Groups)
# Bastion SG: SSH nyitott a világ felé
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

# Web SG: SSH csak a Bastion-tól, HTTP bárhonnan
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

# 6. Szerverek (EC2 Instances)
# Bastion Host
resource "aws_instance" "bastion" {
  ami                    = "ami-0084396898133a8fc" # JAVÍTOTT: Amazon Linux 2023 eu-central-1
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = aws_key_pair.jenkins_key.key_name
  tags = { Name = "Bastion-Host" }
}

# Privát Web Szerver
resource "aws_instance" "web_szerver" {
  ami                    = "ami-0084396898133a8fc" # JAVÍTOTT: Amazon Linux 2023 eu-central-1
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = aws_key_pair.jenkins_key.key_name
  tags = { Name = "Private-Web-Server" }
}

# 7. Outputok a Jenkins Pipeline számára
output "bastion_ip" {
  value = aws_instance.bastion.public_ip
}

output "web_private_ip" {
  value = aws_instance.web_szerver.private_ip
}
