module "networking" {
  source = "./modules/networking"

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  environment          = var.environment
  project_name         = var.project_name
  aws_region           = var.aws_region
}

resource "aws_key_pair" "auth" {
  key_name   = var.key_pair_name
  public_key = file(var.public_key_path)
}

module "security" {
  source = "./modules/security"

  vpc_id       = module.networking.vpc_id
  environment  = var.environment
  project_name = var.project_name
}

module "ecr" {
  source = "./modules/ecr"

  project_name     = var.project_name
  environment      = var.environment
  jenkins_role_arn = module.security.jenkins_role_arn
}

module "jenkins-compute" {
  source = "./modules/jenkins-compute"

  instance_type         = var.jenkins_instance_type
  subnet_id             = module.networking.public_subnet_ids[0]
  security_group_id     = module.security.jenkins_sg_id
  key_pair_name         = aws_key_pair.auth.key_name
  instance_profile_name = module.security.jenkins_instance_profile_name
  environment           = var.environment
  project_name          = var.project_name
}

module "jenkins-agent-spot-compute" {
  source = "./modules/jenkins-agent-spot-compute"

  subnet_ids            = module.networking.private_subnet_ids
  security_group_id     = module.security.jenkins_sg_id
  instance_profile_name = module.security.jenkins_instance_profile_name
  key_pair_name         = aws_key_pair.auth.key_name
  ssh_public_key        = file(var.public_key_path)
  environment           = var.environment
  project_name          = var.project_name
}

module "app-compute" {
  source = "./modules/app-compute"

  instance_type         = var.app_instance_type
  subnet_id             = module.networking.private_subnet_ids[0]
  security_group_id     = module.security.app_sg_id
  key_pair_name         = aws_key_pair.auth.key_name
  instance_profile_name = module.security.app_host_instance_profile_name
  environment           = var.environment
  project_name          = var.project_name
}

module "alb" {
  source = "./modules/alb"

  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
  app_instance_id   = module.app-compute.instance_id
  environment       = var.environment
  project_name      = var.project_name
}
