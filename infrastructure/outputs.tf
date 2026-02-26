output "jenkins_public_ip" {
  description = "Public IP of the Jenkins controller"
  value       = module.jenkins-compute.jenkins_public_ip
}

output "jenkins_public_dns" {
  description = "Public DNS of the Jenkins controller"
  value       = module.jenkins-compute.jenkins_public_dns
}

output "jenkins_url" {
  description = "URL of the Jenkins controller"
  value       = "http://${module.jenkins-compute.jenkins_public_dns}:8080"
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "app_url" {
  description = "URL of the application"
  value       = "http://${module.alb.alb_dns_name}"
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "jenkins_agents_asg_name" {
  description = "Name of the Jenkins agents Auto Scaling Group"
  value       = module.jenkins-agent-spot-compute.autoscaling_group_name
}
