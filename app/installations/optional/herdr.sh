HERDR_OVIS_REF="v0.4.13"
HERDR_DEVCONTAINER_REF="v0.7.3"
HERDR_OVIS_PORT=7317
HERDR_RELAY_PORT=47100
HERDR_ZSHRC_BEGIN="# >>> manjikaze herdr >>>"
HERDR_ZSHRC_END="# <<< manjikaze herdr <<<"

install() {
    if ! command -v docker &> /dev/null; then
        status "Docker is required for devcontainer agents. Install Docker first."
        return 1
    fi

    status "Installing herdr, Bun and the devcontainer CLI with mise..."
    if ! mise use -g herdr@latest bun@latest npm:@devcontainers/cli@latest; then
        status "Failed to install herdr tooling with mise."
        return 1
    fi

    herdr_install_plugin "scott-the-programmer/vscode-devcontainers-herdr" "$HERDR_DEVCONTAINER_REF" "devcontainer-status" || return 1
    herdr_install_plugin "devswha/ovis" "$HERDR_OVIS_REF" "ovis" || return 1

    if command -v claude &> /dev/null; then
        status "Installing the herdr integration for Claude Code..."
        mise exec -- herdr integration install claude || status "Failed to install the Claude Code integration."
    fi

    herdr_configure_sidebar
    herdr_configure_zshrc
    # Interactive zsh so the herdr server inherits mise and the .zshrc settings
    add_gnome_shortcut "herdr" "Herdr" "alacritty -e zsh -ic herdr" "<Super><Control>Return"
    herdr_configure_tailscale
    herdr_configure_tailscale_serve

    status "Herdr installed. Open a new terminal and run 'herdr' in a project directory."
    status "Start an agent inside the devcontainer with 'hdc' after 'devcontainer up --workspace-folder .'."
}

uninstall() {
    if mise exec -- herdr status server &> /dev/null; then
        if gum confirm "Stop the running herdr server and all agents in it?"; then
            mise exec -- herdr server stop || status "Failed to stop the herdr server."
        fi
    fi

    mise exec -- herdr plugin uninstall devswha/ovis || status "Failed to uninstall Ovis."
    mise exec -- herdr plugin uninstall scott-the-programmer/vscode-devcontainers-herdr || status "Failed to uninstall the devcontainer plugin."

    if tailscale serve status 2> /dev/null | grep -q "127.0.0.1:${HERDR_OVIS_PORT}"; then
        tailscale serve --https=443 off || status "Failed to remove the Tailscale serve route."
    fi

    local bridge_ip
    bridge_ip=$(sed -n 's/^export HERDR_BRIDGE_BIND=//p' "$HOME/.zshrc")
    if [ -n "$bridge_ip" ] && systemctl is-active --quiet ufw; then
        sudo ufw delete allow proto tcp from 172.16.0.0/12 to "$bridge_ip" port "$HERDR_RELAY_PORT" || status "Failed to remove the herdr relay ufw rule."
    fi

    sed -i "/^${HERDR_ZSHRC_BEGIN}$/,/^${HERDR_ZSHRC_END}$/d" "$HOME/.zshrc"
    remove_gnome_shortcut "herdr"

    if ! mise unuse -g herdr npm:@devcontainers/cli; then
        status "Failed to remove herdr from mise."
        return 1
    fi

    status "Herdr removed. Tailscale, Bun and ~/.config/herdr are left in place."
}

herdr_install_plugin() {
    local source=$1
    local ref=$2
    local name=$3

    if mise exec -- herdr plugin list 2> /dev/null | grep -q "$name"; then
        status "Herdr plugin '$name' is already installed. Skipping."
        return 0
    fi

    status "Installing herdr plugin $source@$ref..."
    if ! mise exec -- herdr plugin install "$source" --ref "$ref"; then
        status "Failed to install herdr plugin $source."
        return 1
    fi
}

herdr_configure_sidebar() {
    local config="$HOME/.config/herdr/config.toml"
    local rows='ui.sidebar.agents.rows = [["state_icon", "workspace", "tab"], ["agent", "$devcontainer"]]'

    mkdir -p "$(dirname "$config")"
    touch "$config"

    if grep -q '\$devcontainer' "$config"; then
        return 0
    fi

    if grep -q "sidebar" "$config"; then
        status "Herdr sidebar is already customized. Add '\$devcontainer' to ui.sidebar.agents.rows manually."
        return 0
    fi

    # Dotted top-level keys must come before any [table] in TOML
    if ! { echo "$rows"; cat "$config"; } > "$config.tmp" || ! mv "$config.tmp" "$config"; then
        status "Failed to configure the herdr sidebar."
        return 1
    fi
    status "Added devcontainer status to the herdr sidebar."
}

herdr_configure_zshrc() {
    local zshrc="$HOME/.zshrc"
    local bridge_ip
    bridge_ip=$(ip -4 -o addr show docker0 2> /dev/null | awk '{print $4}' | cut -d/ -f1)

    local expose_bridge=false
    if [ -n "$bridge_ip" ]; then
        echo "Native Docker needs the herdr control socket on the docker bridge ($bridge_ip)."
        echo "Every container on that bridge can then control herdr without authentication."
        echo "Without it, agents still run in the container but their state is read from the screen."
        if gum confirm "Expose the herdr control socket on $bridge_ip?"; then
            expose_bridge=true
            herdr_configure_firewall "$bridge_ip"
        fi
    else
        status "No docker0 bridge found. Skipping relay configuration."
    fi

    sed -i "/^${HERDR_ZSHRC_BEGIN}$/,/^${HERDR_ZSHRC_END}$/d" "$zshrc"

    {
        echo "$HERDR_ZSHRC_BEGIN"
        # Newest installation only; herdr keeps the previous one until cleanup
        echo 'for _herdr_bin in "$HOME/.config/herdr/plugins/github-installations"/devcontainer-status-*/*/checkout/bin(N/om[1]); do'
        echo '    export PATH="$_herdr_bin:$PATH"'
        echo 'done'
        echo 'unset _herdr_bin'
        if [ "$expose_bridge" = true ]; then
            echo "export HERDR_RELAY_HOST=$bridge_ip"
            echo "export HERDR_BRIDGE_BIND=$bridge_ip"
        fi
        echo 'export OVIS_TELEMETRY=0'
        echo "alias hdc='herdr-devcontainer-status exec claude'"
        echo "alias hds='herdr-devcontainer-status exec --agent claude bash'"
        echo "alias hdx='herdr-devcontainer-status exec codex'"
        echo "alias dcsh='devcontainer exec --workspace-folder \"\$(git rev-parse --show-toplevel)\" zsh'"
        echo "$HERDR_ZSHRC_END"
    } >> "$zshrc"

    status "Added herdr settings to .zshrc."
}

# Compose networks get their own bridge, so allow all Docker subnets, not just docker0
herdr_configure_firewall() {
    local bridge_ip=$1

    if ! systemctl is-active --quiet ufw; then
        return 0
    fi

    if ! sudo ufw allow proto tcp from 172.16.0.0/12 to "$bridge_ip" port "$HERDR_RELAY_PORT" comment "herdr devcontainer relay"; then
        status "Failed to allow the herdr relay through ufw."
        return 1
    fi
}

herdr_tailscale_running() {
    tailscale status --json 2> /dev/null | grep -q '"BackendState": "Running"'
}

herdr_configure_tailscale() {
    install_package "tailscale" repo

    if ! sudo systemctl enable --now tailscaled.service; then
        status "Failed to start the Tailscale daemon."
        return 1
    fi

    if ! sudo tailscale set --operator="$USER"; then
        status "Failed to set $USER as Tailscale operator."
    fi

    if ! herdr_tailscale_running; then
        status "Log in to Tailscale with the link below..."
        if ! sudo tailscale up; then
            status "Tailscale login failed. Phone access is not configured."
            return 1
        fi
    fi

    if gum confirm "Enable Tailscale SSH as a fallback for phone access?"; then
        sudo tailscale set --ssh || status "Failed to enable Tailscale SSH."
    fi
}

herdr_configure_tailscale_serve() {
    if ! herdr_tailscale_running; then
        status "Tailscale is not running. Skipping the Ovis serve route."
        return 0
    fi

    local serve_status
    serve_status=$(tailscale serve status 2>&1)

    if echo "$serve_status" | grep -q "127.0.0.1:${HERDR_OVIS_PORT}"; then
        status "Ovis is already served over Tailscale."
        return 0
    fi

    if ! echo "$serve_status" | grep -q "No serve config"; then
        status "Tailscale serve is already in use. Add Ovis manually: tailscale serve --bg --https=<port> http://127.0.0.1:${HERDR_OVIS_PORT}"
        return 0
    fi

    if ! tailscale serve --bg --https=443 "http://127.0.0.1:${HERDR_OVIS_PORT}"; then
        status "Failed to serve Ovis over Tailscale."
        return 1
    fi
    status "Ovis is available on your tailnet. Open the HTTPS address from 'tailscale serve status' on your phone."
}
