provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "web_github" {
  name        = "web-github"
  description = "Allow SSH and HTTP"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
  from_port   = 5000
  to_port     = 5000
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_github" {
  ami             = "ami-0e86e20dae9224db8"
  instance_type   = var.instance_type
  key_name        = "vockey"
  security_groups = [aws_security_group.web_github.name]

  tags = {
    Name = "academy-web_github"
  }

  user_data = <<-EOF
              #!/bin/bash

              apt-get update -y
              apt-get install -y python3 python3-pip python3-venv git

              cd /home/ubuntu

              git clone https://github.com/SpartanOfTheBigMac/DevOpsApp.git

              cd DevOpsApp

              python3 -m venv venv

              source venv/bin/activate

              pip install --upgrade pip
              pip install -r requirements.txt

              gunicorn --bind 0.0.0.0:5000 DevOpsApp:app
              EOF
}



output "ec2_public_ip" {
  value = aws_instance.web_github.public_ip
}

