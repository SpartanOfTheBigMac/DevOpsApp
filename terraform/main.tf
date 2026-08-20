terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  # Credentials are supplied via environment variables in CI
  # (AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY / AWS_SESSION_TOKEN)
  # because AWS Academy Learner Lab issues temporary STS credentials.
}

# --- Use the Learner Lab's default VPC/subnet (Learner Lab restricts
#     creation of new VPCs / IAM roles, so we work within what's provided) ---
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- Security group: SSH for deployment, 5000 for the app ---
resource "aws_security_group" "app_sg" {
  name        = "devops-pipeline-app-sg"
  description = "Allow SSH (deploy) and HTTP app traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH for CI/CD deployment"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  ingress {
    description = "Flask app"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "devops-pipeline-app-sg"
    Project = "devops-pipeline-demo"
  }
}

# --- SSH key pair, injected from the public key stored in GitHub Secrets ---
resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = var.ssh_public_key
}

# --- Latest Ubuntu 22.04 AMI ---
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- EC2 instance. Uses the Learner Lab's pre-existing instance profile
#     (LabInstanceProfile) since students cannot create IAM roles. ---
resource "aws_instance" "app_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  key_name                    = aws_key_pair.deployer.key_name
  iam_instance_profile        = var.instance_profile_name
  associate_public_ip_address = true

  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name    = "devops-pipeline-app"
    Project = "devops-pipeline-demo"
  }
}
