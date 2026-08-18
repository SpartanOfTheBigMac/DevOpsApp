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
    description = "HTTP"
    from_port   = 80
    to_port     = 80
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
  ami           = "ami-0e86e20dae9224db8"
  instance_type = var.instance_type
  key_name      = "vockey"
  security_groups = [aws_security_group.web_github.name]

  tags = {
    Name = "academy-web_github"
  }
}

output "ec2_public_ip" {
  value = aws_instance.web_github.public_ip
}

