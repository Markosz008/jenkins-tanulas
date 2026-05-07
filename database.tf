# RDS alhálózat csoport (Az RDS-nek legalább 2 alhálózat kell különböző zónákban)
resource "aws_db_subnet_group" "db_subnets" {
  name       = "main_db_subnet_group"
  subnet_ids = [aws_subnet.private_subnet.id, aws_subnet.private_subnet_2.id]

  tags = {
    Name = "My DB Subnet Group"
  }
}

# RDS MySQL példány - AWS Free Tier (t3.micro)
resource "aws_db_instance" "mysql_db" {
  allocated_storage    = 20 # Minimum 20 GB az RDS-nek
  db_name              = "devopsdb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro" # Free Tier kompatibilis
  username             = "admin"
  password             = var.db_password # Változót használunk!
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  
  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  tags = {
    Name = "DevOps-Adatbazis"
  }
}

# Security Group az adatbázisnak (hogy csak a webszerver érje el)
resource "aws_security_group" "db_sg" {
  name        = "db_sg"
  description = "Engedélyezi a MySQL forgalmat a webszerver felől"
  vpc_id      = aws_vpc.elso_halozatom.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id] # Csak a web_sg-ből jöhet kérés!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}