#!/bin/bash

YUBIKEY_SSH_ENV_FILE="$HOME/.config/environment.d/50-yubikey-gpg-ssh.conf"

# Desktop apps (SmartGit, VS Code, ...) don't read .zshrc, so they only use gpg-agent and the
# YubiKey for SSH when the session itself has SSH_AUTH_SOCK. systemd reads environment.d at
# every login, in GNOME and Hyprland alike; set-environment covers the current session.
yubikey_configure_desktop_ssh_agent() {
    local socket
    socket=$(gpgconf --list-dirs agent-ssh-socket)

    mkdir -p "$(dirname "$YUBIKEY_SSH_ENV_FILE")"
    cat >"$YUBIKEY_SSH_ENV_FILE" <<EOF
# Written by Manjikaze: desktop apps use gpg-agent (and so the YubiKey) for SSH.
SSH_AUTH_SOCK=$socket
EOF

    systemctl --user set-environment SSH_AUTH_SOCK="$socket" 2>/dev/null || true
    # Older setups imported a terminal's GPG_TTY into the session; desktop apps have no tty.
    systemctl --user unset-environment GPG_TTY 2>/dev/null || true
}
