install() {
    install_package "docker-rootless-extras" aur

    systemctl --user enable --now docker.socket

    if ! docker context inspect rootless &>/dev/null; then
        docker context create rootless --docker "host=unix://$XDG_RUNTIME_DIR/docker.sock"
    fi

    status "Rootless Docker installed. Switch contexts with:"
    status "  docker context use rootless  (user daemon, no root needed)"
    status "  docker context use default   (system daemon, requires docker group)"
}

uninstall() {
    systemctl --user disable --now docker.socket

    docker context rm rootless 2>/dev/null || true

    uninstall_package "docker-rootless-extras" aur
}
