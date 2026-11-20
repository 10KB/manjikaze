# Codex. Manjikaze updates it, so Codex doesn't check for updates. /etc/codex/config.toml holds
# the defaults that ~/.codex/config.toml overrides.
AGENT_TOOL="codex"
CODEX_SYSTEM_CONFIG="/etc/codex/config.toml"

install() {
    install_mise_tool codex "$HOME/.codex/packages/standalone" codex || return 1

    if [[ ! -e $CODEX_SYSTEM_CONFIG ]] || cmp -s "$MANJIKAZE_DIR/configs/codex/config.toml" "$CODEX_SYSTEM_CONFIG"; then
        install_system_file "$MANJIKAZE_DIR/configs/codex/config.toml" "$CODEX_SYSTEM_CONFIG"
    elif ! grep -q '^check_for_update_on_startup = false' "$CODEX_SYSTEM_CONFIG"; then
        status "Add 'check_for_update_on_startup = false' to $CODEX_SYSTEM_CONFIG: Manjikaze updates Codex."
    fi
}

uninstall() {
    uninstall_mise_tool codex
    if cmp -s "$MANJIKAZE_DIR/configs/codex/config.toml" "$CODEX_SYSTEM_CONFIG"; then
        sudo rm "$CODEX_SYSTEM_CONFIG"
    fi
}
