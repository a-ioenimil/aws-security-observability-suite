FROM jenkins/ssh-agent:latest

USER root

# -------------------------------------------------------
# 1. Base utilities
# -------------------------------------------------------
RUN apt-get update && \
    apt-get install -y ca-certificates curl gnupg unzip && \
    rm -rf /var/lib/apt/lists/*

# -------------------------------------------------------
# 2. Docker CE CLI + Buildx + Compose (official repo)
# -------------------------------------------------------
RUN for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do \
    apt-get remove -y "$pkg" 2>/dev/null || true; \
    done

RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null

RUN apt-get update && \
    apt-get install -y docker-ce-cli docker-buildx-plugin docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/*

# -------------------------------------------------------
# 3. AWS CLI v2
# -------------------------------------------------------
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" && \
    unzip -q /tmp/awscliv2.zip -d /tmp && \
    /tmp/aws/install && \
    rm -rf /tmp/aws /tmp/awscliv2.zip

# -------------------------------------------------------
# 4. uv (Python package manager)
# -------------------------------------------------------
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="/usr/local/bin" sh
