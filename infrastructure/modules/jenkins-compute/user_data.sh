#!/bin/bash
set -euo pipefail

# 1. Update all system packages
yum update -y

# 2. Install Java 17 (Corretto first as preferred)
yum install java-17-amazon-corretto -y

# 3. Install Jenkins LTS
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
yum install jenkins -y

# 4. Install Docker
yum install docker -y
systemctl enable docker
systemctl start docker
usermod -aG docker jenkins
usermod -aG docker ec2-user

# 5. Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
aws --version

# 6. Install git
yum install git -y

# 7. Enable and start Jenkins
systemctl enable jenkins
systemctl start jenkins

# 8. Log the initial admin password location
echo "Jenkins initial password at: /var/lib/jenkins/secrets/initialAdminPassword"
# Wait for the file to exist (simple wait loop, though systemctl start usually blocks until ready)
while [ ! -f /var/lib/jenkins/secrets/initialAdminPassword ]; do sleep 2; done
cat /var/lib/jenkins/secrets/initialAdminPassword > /var/log/jenkins-init.log