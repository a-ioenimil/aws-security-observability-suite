variable "subnet_ids" {
  description = "List of Subnet IDs for the agents"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security Group ID for the agents"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM Instance Profile Name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair to use"
  type        = string
}

variable "ssh_public_key" {
  description = "Public key content for the Docker SSH agent"
  type        = string
}

