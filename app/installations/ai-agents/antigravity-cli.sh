# Google's Antigravity CLI, agy. It works without the Antigravity app.
AGENT_TOOL="agy"
AGY_ENVIRONMENT_FILE="$HOME/.config/environment.d/50-antigravity-cli.conf"

install() {
    # The vendor's installer copies agy into ~/.local/bin, next to the agy.*.old files of its updates.
    install_mise_tool agy "$HOME/.local/bin/agy" agy || return 1
    rm -f "$HOME"/.local/bin/agy.*.old

    # agy replaces its own executable when it updates, also inside mise's installs. Only this
    # variable stops that, and only with the value true. systemd reads environment.d at every
    # login; set-environment covers the current session.
    mkdir -p "$(dirname "$AGY_ENVIRONMENT_FILE")"
    echo "AGY_CLI_DISABLE_AUTO_UPDATE=true" > "$AGY_ENVIRONMENT_FILE"
    systemctl --user set-environment AGY_CLI_DISABLE_AUTO_UPDATE=true 2> /dev/null || true
    status "Log out and back in before you use agy in a terminal that was already open."
}

uninstall() {
    uninstall_mise_tool agy
    rm -f "$AGY_ENVIRONMENT_FILE"
    systemctl --user unset-environment AGY_CLI_DISABLE_AUTO_UPDATE 2> /dev/null || true
}
