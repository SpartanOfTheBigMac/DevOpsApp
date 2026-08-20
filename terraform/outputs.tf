output "public_ip" {
  description = "Public IP address of the deployed EC2 instance"
  value       = aws_instance.app_server.public_ip
}

output "public_dns" {
  description = "Public DNS name of the deployed EC2 instance"
  value       = aws_instance.app_server.public_dns
}

output "app_url" {
  description = "URL where the deployed application will be reachable"
  value       = "http://${aws_instance.app_server.public_ip}:5000"
}
