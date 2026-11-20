# Claude Code. Manjikaze updates it, so managed settings, which apply to every Claude Code on the
# machine, switch off its own updates.
AGENT_TOOL="claude"
CLAUDE_CODE_MANAGED_SETTINGS="/etc/claude-code/managed-settings.d/manjikaze-mise.json"

install() {
    install_mise_tool claude "$HOME/.local/share/claude" claude || return 1
    install_system_file "$MANJIKAZE_DIR/configs/claude-code/managed-settings.json" "$CLAUDE_CODE_MANAGED_SETTINGS"
}

uninstall() {
    uninstall_mise_tool claude
    sudo rm -f "$CLAUDE_CODE_MANAGED_SETTINGS"
}
