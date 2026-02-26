variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "jenkins_role_arn" {
  description = "ARN of the Jenkins IAM role"
  type        = string
}
