output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.jenkins_agent.id
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.jenkins_agents.name
}
