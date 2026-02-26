#!/bin/bash
set -euo pipefail

# -------------------------------------------------------
# EC2 Host Setup
# -------------------------------------------------------

# Update packages
yum update -y

# Install Docker
yum install docker -y
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# Install AWS CLI v2 (on the host, needed to authenticate to ECR)
yum install unzip -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Give all users access to the Docker socket
chmod 666 /var/run/docker.sock

# -------------------------------------------------------
# Pull and run the custom Jenkins SSH Agent from ECR
# -------------------------------------------------------

AWS_REGION="eu-west-1"
ECR_REGISTRY="867344428625.dkr.ecr.eu-west-1.amazonaws.com"
AGENT_IMAGE="$${ECR_REGISTRY}/jenkins-ssh-agent-custom:latest"

# Authenticate Docker to ECR so we can pull the custom image
aws ecr get-login-password --region "$${AWS_REGION}" | \
  docker login --username AWS --password-stdin "$${ECR_REGISTRY}"

# Run the custom Jenkins SSH Agent (all tools are pre-installed in the image)
docker run -d \
  --name jenkins-agent \
  --restart=on-failure \
  -p 2222:22 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e "JENKINS_AGENT_SSH_PUBKEY=${ssh_public_key}" \
  "$${AGENT_IMAGE}"

echo "Jenkins agent setup complete. SSH on port 2222 with the provided key."
