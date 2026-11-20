# The Cursor CLI, agent and cursor-agent. The Cursor editor is the optional app cursor.
AGENT_TOOL="cursor-agent"

# The CLI looks for its settings in this order.
cursor_cli_config() {
    if [[ -n ${CURSOR_CONFIG_DIR:-} ]]; then
        echo "$CURSOR_CONFIG_DIR/cli-config.json"
    elif [[ -n ${XDG_CONFIG_HOME:-} ]]; then
        echo "$XDG_CONFIG_HOME/cursor/cli-config.json"
    else
        echo "$HOME/.cursor/cli-config.json"
    fi
}

install() {
    # ~/.local/share/cursor-agent also holds the CLI's logs, so only its versions make way.
    install_mise_tool cursor-agent "$HOME/.local/share/cursor-agent/versions" cursor-agent agent || return 1

    # Manjikaze updates the CLI. On the static channel, it doesn't update itself.
    local config
    config=$(cursor_cli_config)
    mkdir -p "$(dirname "$config")"
    if [[ -s $config ]]; then
        jq '.channel = "static"' "$config" > "$config.tmp" && mv "$config.tmp" "$config"
    else
        echo '{"channel": "static"}' > "$config"
    fi
}

uninstall() {
    local config
    uninstall_mise_tool cursor-agent
    config=$(cursor_cli_config)
    if [[ -s $config ]] && jq -e '.channel == "static"' "$config" > /dev/null; then
        jq 'del(.channel)' "$config" > "$config.tmp" && mv "$config.tmp" "$config"
    fi
}
