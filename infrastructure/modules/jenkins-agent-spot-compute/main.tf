data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_launch_template" "jenkins_agent" {
  name_prefix   = "${var.project_name}-${var.environment}-jenkins-agent-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.medium"
  
  lifecycle {
    create_before_destroy = true
  }
  



  key_name = var.key_pair_name

  vpc_security_group_ids = [var.security_group_id]

  iam_instance_profile {
    name = var.instance_profile_name
  }

  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price          = ""
      spot_instance_type = "one-time"
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    ssh_public_key = var.ssh_public_key
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-${var.environment}-jenkins-agent"
      Environment = var.environment
      Project     = var.project_name
      Role        = "jenkins-agent"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name        = "${var.project_name}-${var.environment}-jenkins-agent-volume"
      Environment = var.environment
      Project     = var.project_name
    }
  }
}

resource "aws_autoscaling_group" "jenkins_agents" {
  name                = "${var.project_name}-${var.environment}-jenkins-agents-asg"
  min_size            = 0
  max_size            = 3
  desired_capacity    = 0
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.jenkins_agent.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling" # Replaces instances one by one (or in batches)
    
    preferences {
      min_healthy_percentage = 0
    }
    
    # Optional: Explicitly tell it to trigger on launch template changes.
    # Usually implicit when version = "$Latest", but good for clarity.
    triggers = ["tag"] 
  }

  # Tag for Jenkins EC2 plugin discovery
  tag {
    key                 = "JenkinsRole"
    value               = "agent"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-jenkins-agent"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }
}
