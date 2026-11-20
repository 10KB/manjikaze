#!/bin/bash
# Docker runs rootless: the daemon runs as the user. The rootful daemon's socket gives everyone in
# the docker group root without a password, which also bypasses a YubiKey on sudo.

ROOTLESS_DOCKER_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/docker/daemon.json"
ROOTFUL_DOCKER_SOCKET="/run/docker.sock"

configure_rootless_docker() {
    install_package "docker-rootless-extras" aur || true
    if ! is_installed "docker-rootless-extras"; then
        status "Failed to install docker-rootless-extras."
        return 1
    fi

    # The rootless daemon doesn't read /etc/docker/daemon.json, so it gets the same log limits here.
    # They apply the next time the daemon starts.
    if [[ ! -f "$ROOTLESS_DOCKER_CONFIG" ]]; then
        mkdir -p "$(dirname "$ROOTLESS_DOCKER_CONFIG")"
        echo '{"log-driver":"json-file","log-opts":{"max-size":"10m","max-file":"5"}}' > "$ROOTLESS_DOCKER_CONFIG"
    fi

    if ! systemctl --user enable --now docker.socket; then
        status "Failed to start the rootless Docker socket."
        return 1
    fi

    local socket="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/docker.sock"
    if ! docker context inspect rootless &> /dev/null &&
        ! docker context create rootless --docker "host=unix://$socket" > /dev/null; then
        status "Failed to create the rootless Docker context."
        return 1
    fi

    # A context and not DOCKER_HOST in the session: DOCKER_HOST would point every program at one
    # socket, also programs that otherwise look up which user's daemon a container belongs to.
    if ! docker context use rootless > /dev/null; then
        status "Failed to make rootless Docker the default."
        return 1
    fi
    status "Docker uses the rootless daemon."
}

# Its images, containers and volumes stay in /var/lib/docker.
leave_rootful_docker() {
    local containers volumes

    if systemctl is-active --quiet docker.service; then
        containers=$(sudo docker --host "unix://$ROOTFUL_DOCKER_SOCKET" ps -aq | wc -l)
        volumes=$(sudo docker --host "unix://$ROOTFUL_DOCKER_SOCKET" volume ls -q | wc -l)
        if [[ $containers -gt 0 || $volumes -gt 0 ]]; then
            status "The rootful daemon keeps $containers container(s) and $volumes volume(s) in /var/lib/docker."
            status "To reach them: sudo systemctl start docker, then sudo docker ..."
        fi
    fi

    if ! sudo systemctl disable --now docker.socket docker.service; then
        status "Failed to stop the rootful Docker daemon."
        return 1
    fi
    # docker.socket leaves its file behind, and programs would still take it for a running daemon.
    sudo rm -f "$ROOTFUL_DOCKER_SOCKET"

    if id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
        sudo gpasswd -d "$USER" docker > /dev/null
        status "Removed $USER from the docker group. Log out and back in for this to take effect."
    fi
}
