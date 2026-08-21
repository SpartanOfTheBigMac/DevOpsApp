provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "web_github13" {
  name        = "web_github13"
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

data "aws_vpc" "default" {
  default = true
}

data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_default_route_table" "default" {
  default_route_table_id = data.aws_vpc.default.main_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.default.id
  }

  tags = {
    Name = "default-route-table"
  }
}


resource "aws_instance" "web_github13" {
  ami             = "ami-0e86e20dae9224db8"
  instance_type   = var.instance_type
  key_name        = "vockey"
  security_groups = [aws_security_group.web_github13.name]

   depends_on = [aws_default_route_table.default]

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
              pip install flask boto3 gunicorn

              gunicorn --bind 0.0.0.0:80 DevOpsApp:app
              EOF

  tags = {
    Name = "academy-web_github13"
  }
}

output "ec2_public_ip" {
  value = aws_instance.web_github13.public_ip
}