resource "aws_security_group" "web_github" {
  name        = "web-github"
  description = "Allow SSH and HTTP"

provider "AWS" {
  region = "us-east-1"
}

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
  ami           = "ami-0e86e20dae9224db8" # Ubuntu 22.04 LTS (us-east-1)
  instance_type = var.instance_type
  key_name      = "vockey"
  security_groups = [aws_security_group.web_github.name]

  tags = {
    Name = "academy-web_github"
  }
}