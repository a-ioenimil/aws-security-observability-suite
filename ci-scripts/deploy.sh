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

# 2. Pull the latest image
echo "Pulling latest image: ${IMAGE}"
sudo docker pull "${IMAGE}"

# 3. Stop the existing container if running
echo "Stopping existing container..."
sudo docker stop backend-api || true
sudo docker rm backend-api || true

# 4. Start the new container
echo "Starting new container..."
sudo docker run -d \
    --name backend-api \
    --restart unless-stopped \
    -p 80:5000 \
    "${IMAGE}"

# 5. Verify the container is running
echo "Verifying container status..."
sleep 3
if [ "$(sudo docker inspect -f '{{.State.Running}}' backend-api)" = "true" ]; then
    echo "Deployment Successful! Application is running."
else
    echo "Deployment Failed! Container is not running."
    sudo docker logs backend-api
    exit 1
fi

# 6. Clean up old, unused Docker images
echo "Cleaning up..."
sudo docker system prune -af --filter "until=24h"

echo "Deployment finished."

