#!/bin/bash
set -euo pipefail
export PATH=$PATH:/usr/local/bin:/usr/bin

# Read arguments
ECR_REGISTRY=$1
AWS_REGION=$2
IMAGE=$3

echo "Starting Deployment on App Host..."

# 0. Wait for Docker to be ready (user_data may still be running)
echo "Waiting for Docker to be available..."
for i in $(seq 1 30); do
    if command -v docker &>/dev/null && sudo docker info &>/dev/null; then
        echo "Docker is ready."
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "ERROR: Docker is not available after 60 seconds. Check user_data / cloud-init logs."
        exit 1
    fi
    echo "  Attempt $i/30 — Docker not ready yet, waiting 2s..."
    sleep 2
done

# 1. Authenticate Docker with AWS ECR
echo "Authenticating with ECR..."
aws ecr get-login-password --region "${AWS_REGION}" | sudo docker login --username AWS --password-stdin "${ECR_REGISTRY}"

# 2. Pull the latest monitoring images
echo "Pulling latest image: ${IMAGE}"
sudo docker pull "${IMAGE}"


# 4. Start the stack using Docker Compose
echo "Cleaning up legacy standalone container if it exists..."
sudo docker rm -f backend-api || true

echo "Starting stack with Docker Compose..."
cd /home/ec2-user/monitoring
sudo BACKEND_IMAGE="${IMAGE}" docker compose up -d

# 5. Verify the backend container is running
echo "Verifying backend container status..."
sleep 5
if [ "$(sudo docker inspect -f '{{.State.Running}}' monitoring-backend-1 || sudo docker inspect -f '{{.State.Running}}' backend)" = "true" ]; then
    echo "Deployment Successful! Application is running."
else
    echo "Deployment Failed! Backend container is not running."
    sudo docker compose logs backend
    exit 1
fi

# 6. Clean up old, unused Docker images
echo "Cleaning up..."
sudo docker system prune -af --filter "until=24h"

echo "Deployment finished."

