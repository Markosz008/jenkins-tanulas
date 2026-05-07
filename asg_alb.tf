# 1. Launch Template - Ez a "recept", ami alapján a szerverek születnek
resource "aws_launch_template" "web_template" {
  name_prefix   = "web-server-template-"
  image_id      = data.aws_ami.latest_amazon_linux.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.jenkins_key.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_sg.id]
  }

  # Ide tehetnénk egy alap scriptet, de mi az Ansible-t használjuk konfigurálásra!
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ASG-Web-Server"
    }
  }
}

# 2. Application Load Balancer (ALB) - A belépő kapu
resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [aws_subnet.public_subnet.id, aws_subnet.private_subnet_2.id] # Legalább 2 zóna kell neki!

  tags = {
    Name = "Web-App-Load-Balancer"
  }
}

# 3. ALB Target Group - Ide küldi a Load Balancer a forgalmat
resource "aws_lb_target_group" "web_tg" {
  name     = "web-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.elso_halozatom.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

# 4. ALB Listener - Figyeli a 80-as portot
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# 5. Auto Scaling Group - A szerverek kezelője
resource "aws_autoscaling_group" "web_asg" {
  desired_capacity    = 2 # Alapból 2 szerverünk lesz a biztonság kedvéért
  max_size            = 4 # Terhelésre felmegy 4-ig
  min_size            = 1 # Sosem lesz 1-nél kevesebb
  target_group_arns   = [aws_lb_target_group.web_tg.arn]
  vpc_zone_identifier = [aws_subnet.public_subnet.id] # Itt fognak élni a szerverek

  launch_template {
    id      = aws_launch_template.web_template.id
    version = "$Latest"
  }
}