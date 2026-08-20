variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance size (t2.micro/t3.micro are Learner Lab friendly)"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name given to the EC2 key pair"
  type        = string
  default     = "devops-pipeline-key"
}

variable "ssh_public_key" {
  description = "Public key content used to SSH into the instance (passed in from CI)"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed to SSH in. Restrict to your IP (x.x.x.x/32) for a more secure setup — kept open here for the GitHub Actions runner's changing IP."
  type        = string
  default     = "0.0.0.0/0"
}

variable "instance_profile_name" {
  description = "Existing AWS Academy Learner Lab instance profile (do not change unless your lab names it differently)"
  type        = string
  default     = "LabInstanceProfile"
}
