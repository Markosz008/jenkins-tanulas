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

# SSH kulcspár regisztrálása az AWS-ben
resource "aws_key_pair" "jenkins_key" {
  key_name   = "jenkins-key"
  # IDE ILLESZD BE a /var/jenkins_home/id_rsa.pub tartalmát:
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDPN47hdfnKP9ubS6MGGpo+viXlhWsIWOfRUR72tyBhRV4gByf9y5w9IhNvijqVfvvovPu60DtFV/N3ZVrpSmmUF7iSoTshhls8fJ5LizL7Ewyip830Veg2HMpSWuqVDlUDWMhC37UxIngrxmTjQhRHQj6gXLUy33JrpbX9XAIcZJHuwnkvcJZ97Qfxl1x4sLMkhy7ZXW3t+CEPkgwdLmRDJykh263n4sMTqFR05AVm4VsNSf9iriqiwwReRd2QZpdt3e0kXSlt61/JeGIbIandTPU9vKo0XVuDk6VZSTT+Im7ndxBdE7VYczqZQrYVeIkp5WHsKVkM7HtnNNfW7sgBESZN2ZPzl85PEh2QNXQOmXgY9L2IZuUapSHjq3d4MWMNjCZADTp+CBmPZYEwvnMOx01+amamR6PqYXY+hyILzzRZpGui6E6j+6L9j8zSXeTd6lQrBvp+6vtsLB/lJFKxejDeBONbh/UdoVBcwxrUf3I8gGNHAj/h0bBGiOUAshAvt9o9zxENZy2GlGGy0gbnRMvwV59HZLyPnDTUg/2o+QkI2RyGc+WH9FpLY5ZKaQ5PXIkIdgXGfBv3FT3by+FkT7S6K/3pg8ZP7IWlGyQNs4lEWvNapQKR5mnl20xK9Kl87qfQzOflsAWBtu5lEb8EflfEoKH64tcJ6/BOdLa0BQ== root@d35f67224ea7" 
}

# 1. A hálózat (VPC)
resource "aws_vpc" "elso_halozatom" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Jenkins-VPC-Projekt"
  }
}

# 2. Alhálózat (Subnet)
resource "aws_subnet" "elso_alhalozat" {
  vpc_id                  = aws_vpc.elso_halozatom.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "Ansible-Subnet"
  }
}

# Internet Gateway a kommunikációhoz (fontos az SSH-hoz!)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.elso_halozatom.id
}

resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.elso_halozatom.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.elso_alhalozat.id
  route_table_id = aws_route_table.main_rt.id
}

# 3. Biztonsági csoport
resource "aws_security_group" "jenkins_access" {
  name        = "jenkins_access"
  vpc_id      = aws_vpc.elso_halozatom.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

# 4. Az EC2 Szerver
resource "aws_instance" "web_szerver" {
  ami                    = "ami-08bdb1495db49a7f9" 
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.elso_alhalozat.id
  vpc_security_group_ids = [aws_security_group.jenkins_access.id]
  key_name               = aws_key_pair.jenkins_key.key_name # Itt rendeljük hozzá a kulcsot!

  tags = {
    Name = "Ansible-Target-Server"
  }
}

# Ez a sor kell, hogy a Jenkins ki tudja olvasni az IP címet!
output "public_ip" {
  value = aws_instance.web_szerver.public_ip
}
