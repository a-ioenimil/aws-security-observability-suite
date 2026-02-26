output "jenkins_sg_id" {
  description = "ID of the Jenkins Security Group"
  value       = aws_security_group.jenkins_sg.id
}

output "app_sg_id" {
  description = "ID of the App Security Group"
  value       = aws_security_group.app_sg.id
}

output "alb_sg_id" {
  description = "ID of the ALB Security Group"
  value       = aws_security_group.alb_sg.id
}

output "jenkins_role_arn" {
  description = "ARN of the Jenkins IAM Role"
  value       = aws_iam_role.jenkins_role.arn
}

output "jenkins_instance_profile_name" {
  description = "Name of the Jenkins Instance Profile"
  value       = aws_iam_instance_profile.jenkins_instance_profile.name
}

output "app_host_instance_profile_name" {
  description = "Name of the App Host Instance Profile"
  value       = aws_iam_instance_profile.app_host_instance_profile.name
}
