# 1. VPC és hálózat marad, de adunk hozzá egy privát alhálózatot
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "Main-VPC" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# Publikus alhálózat a Bastion-nak
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = { Name = "Public-Subnet" }
}

# Privát alhálózat a Web szervernek
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  tags = { Name = "Private-Subnet" }
}

# Route Table a publikus eléréshez
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.pub_rt.id
}

# --- SECURITY GROUPS ---

# Bastion SG: Csak SSH kívülről
resource "aws_security_group" "bastion_sg" {
  name   = "bastion-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Élesben ide a saját IP-det írnád!
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
  name   = "web-sg"
  vpc_id = aws_vpc.main.id
  
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id] # KULCSFONTOSSÁGÚ!
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

# --- PÉLDÁNYOK ---

# Bastion Host
resource "aws_instance" "bastion" {
  ami           = "ami-0ed09467776413204" # Amazon Linux 2023 eu-central-1
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name      = "jenkins-key"
  tags = { Name = "Bastion-Host" }
}

# Web Szerver (Privát!)
resource "aws_instance" "web_szerver" {
  ami           = "ami-0ed09467776413204"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name      = "jenkins-key"
  tags = { Name = "Web-Server-Private" }
}

output "bastion_ip" { value = aws_instance.bastion.public_ip }
output "web_private_ip" { value = aws_instance.web_szerver.private_ip }
