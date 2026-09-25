install() {
    install_package "go" repo
    install_package "zenity" repo

    if ! command -v go &> /dev/null; then
        status "Go is required to build host-gate but is not available. Aborting."
        return 1
    fi

    status "Building host-gate binaries..."
    local HOST_GATE_DIR="$MANJIKAZE_DIR/host-gate"

    (cd "$HOST_GATE_DIR" && make build)

    sudo install -m 755 "$HOST_GATE_DIR/bin/host-gate-daemon" /usr/local/bin/
    sudo install -m 755 "$HOST_GATE_DIR/bin/host-gate-client-linux-amd64" /usr/local/bin/host-gate-client

    local RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/host-gate"
    mkdir -p "$RUNTIME_DIR"
    cp "$HOST_GATE_DIR"/bin/host-gate-client-linux-* "$RUNTIME_DIR/"
    chmod 755 "$RUNTIME_DIR"/host-gate-client-linux-*

    status "Creating default host policy config..."
    mkdir -p "$HOME/.config/host-gate"
    if [ ! -f "$HOME/.config/host-gate/policy.json" ]; then
        cp "$HOST_GATE_DIR/configs/default-policy.json" "$HOME/.config/host-gate/policy.json"
        status "Default policy config installed at ~/.config/host-gate/policy.json"
    else
        status "Host policy config already exists, skipping."
    fi

    status "Setting up systemd user service..."
    mkdir -p "$HOME/.config/systemd/user"
    cp "$HOST_GATE_DIR/systemd/host-gate.service" "$HOME/.config/systemd/user/"

    systemctl --user daemon-reload
    systemctl --user enable --now host-gate.service

    status "Host gate installed. Edit ~/.config/host-gate/policy.json to configure allowed commands."
}

uninstall() {
    systemctl --user disable --now host-gate.service 2>/dev/null || true
    rm -f "$HOME/.config/systemd/user/host-gate.service"
    systemctl --user daemon-reload

    sudo rm -f /usr/local/bin/host-gate-daemon
    sudo rm -f /usr/local/bin/host-gate-client

    uninstall_package "zenity" repo
}
