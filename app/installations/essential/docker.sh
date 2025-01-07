install_docker() {
    status "Installing Docker..."
    if ! sudo pamac install docker docker-buildx --no-confirm; then
        status "Failed to install Docker packages."
        return 1
    fi

    if ! sudo usermod -aG docker "${USER}"; then
        status "Failed to add user to docker group."
        return 1
    fi

    # Limit log size to avoid running out of disk
    sudo mkdir -p /etc/docker
    if ! echo '{"log-driver":"json-file","log-opts":{"max-size":"10m","max-file":"5"}}' | sudo tee /etc/docker/daemon.json > /dev/null; then
        status "Failed to set Docker log limits."
        return 1
    fi

    # Configure userns-remap to use the current user
    # current_user=$(whoami)
    # if ! sudo jq --arg user "$current_user" '. + {"userns-remap": $user}' /etc/docker/daemon.json | sudo tee /etc/docker/daemon.json > /dev/null; then
    #     status "Failed to configure userns-remap."
    #     return 1
    # fi

    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p "$DOCKER_CONFIG/cli-plugins"

    LATEST_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
    if [ -z "$LATEST_COMPOSE_VERSION" ]; then
        status "Failed to fetch latest Docker Compose version."
        return 1
    fi

    if ! curl -sSL "https://github.com/docker/compose/releases/download/${LATEST_COMPOSE_VERSION}/docker-compose-linux-x86_64" -o "$DOCKER_CONFIG/cli-plugins/docker-compose"; then
        status "Failed to download Docker Compose."
        return 1
    fi

    if ! chmod +x "$DOCKER_CONFIG/cli-plugins/docker-compose"; then
        status "Failed to set execute permissions on Docker Compose."
        return 1
    fi

    if ! sudo systemctl enable docker.service; then
        status "Failed to enable Docker service."
        return 1
    fi

    status "Docker installation completed successfully."
}

install_docker