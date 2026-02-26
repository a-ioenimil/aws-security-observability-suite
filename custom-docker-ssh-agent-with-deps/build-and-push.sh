#!/bin/bash
set -euo pipefail

# -------------------------------------------------------
# Configuration — update these to match your environment
# -------------------------------------------------------
AWS_REGION="eu-west-1"
ECR_REGISTRY="867344428625.dkr.ecr.eu-west-1.amazonaws.com"
ECR_REPOSITORY="jenkins-ssh-agent-custom"
IMAGE_TAG="latest"

FULL_IMAGE="${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"

# -------------------------------------------------------
# 1. Authenticate Docker to ECR
# -------------------------------------------------------
echo "Authenticating to ECR..."
aws ecr get-login-password --region "${AWS_REGION}" | \
  docker login --username AWS --password-stdin "${ECR_REGISTRY}"

# -------------------------------------------------------
# 2. Build the custom image
# -------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Building image from ${SCRIPT_DIR}..."
docker build -t "${FULL_IMAGE}" "${SCRIPT_DIR}"

# -------------------------------------------------------
# 3. Push to ECR
# -------------------------------------------------------
echo "Pushing ${FULL_IMAGE}..."
docker push "${FULL_IMAGE}"

echo ""
echo "Done! Image pushed to: ${FULL_IMAGE}"
echo "Use this image URI in your user_data.sh docker run command."
