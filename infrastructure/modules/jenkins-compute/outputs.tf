output "jenkins_public_ip" {
  description = "Public IP of the Jenkins controller"
  value       = aws_eip.jenkins_eip.public_ip
}

output "jenkins_public_dns" {
  description = "Public DNS of the Jenkins controller"
  value       = aws_eip.jenkins_eip.public_dns
}

output "instance_id" {
  description = "ID of the Jenkins controller instance"
  value       = aws_instance.jenkins_controller.id
}
