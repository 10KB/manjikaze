source "$MANJIKAZE_DIR/lib/tailscale.sh"

install() {
    install_tailscale || return 1
    log_in_to_tailscale
}

uninstall() {
    uninstall_tailscale
}
