#!/bin/bash
# Stop execution if any command fails (except those explicitly allowed with || true)
set -euo pipefail

# Redirect all output to a dedicated log file AND the standard cloud-init log
exec > >(tee /var/log/user-data-setup.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "--- Starting EC2 Initialization ---"

# 1. Update packages (non-fatal)
echo "Updating existing packages..."
yum update -y || true

# 2. Install core utilities (unzip is required for the AWS CLI installation)
echo "Installing git and unzip..."
yum install -y git unzip

# 3. Install Docker (The correct way for Amazon Linux 2)
echo "Installing Docker from amazon-linux-extras..."
amazon-linux-extras install docker -y

# Start and enable Docker to survive reboots
echo "Starting Docker service..."
systemctl enable --now docker

# Add ec2-user to the docker group
usermod -aG docker ec2-user

# 4. Install Docker Compose plugin
echo "Installing Docker Compose v2..."
mkdir -p /usr/local/lib/docker/cli-plugins/
curl -SL https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# 5. Install AWS CLI v2
echo "Downloading and installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
# Use -q (quiet) to prevent massive log spam from unzip
unzip -q -o /tmp/awscliv2.zip -d /tmp/
/tmp/aws/install --update
rm -rf /tmp/aws /tmp/awscliv2.zip

# 5. Log completion
echo "App host ready at $(date)" >> /var/log/app-host-init.log
echo "Docker, AWS CLI, and git installed successfully." >> /var/log/app-host-init.log
echo "--- EC2 Initialization Completed Successfully ---"