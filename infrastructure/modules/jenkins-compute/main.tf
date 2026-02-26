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

resource "aws_instance" "jenkins_controller" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = var.key_pair_name
  iam_instance_profile        = var.instance_profile_name
  user_data                   = file("${path.module}/user_data.sh")
  user_data_replace_on_change = true
  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-jenkins-controller"
    Environment = var.environment
    Project     = var.project_name
    Role        = "jenkins-controller"
  }
}

resource "aws_eip" "jenkins_eip" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-${var.environment}-jenkins-eip"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_eip_association" "jenkins_eip_assoc" {
  instance_id   = aws_instance.jenkins_controller.id
  allocation_id = aws_eip.jenkins_eip.id
}
