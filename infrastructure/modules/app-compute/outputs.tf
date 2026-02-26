output "instance_id" {
  description = "ID of the app host instance"
  value       = aws_instance.app_host.id
}

output "private_ip" {
  description = "Private IP of the app host instance"
  value       = aws_instance.app_host.private_ip
}
