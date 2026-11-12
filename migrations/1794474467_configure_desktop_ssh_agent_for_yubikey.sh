#!/bin/bash
set -e

# Desktop apps only reached gpg-agent's SSH socket in the session where the YubiKey setup ran.
# After a new login, and in Hyprland, apps like SmartGit couldn't push with the YubiKey.

if ! grep -qs '^enable-ssh-support' "$HOME/.gnupg/gpg-agent.conf"; then
    status "gpg-agent SSH support is not configured, skipping."
    return 0
fi

source "$MANJIKAZE_DIR/app/security/yubikey/yubikey-desktop-ssh-agent.sh"
yubikey_configure_desktop_ssh_agent
status "Desktop apps now use gpg-agent for SSH. Restart open apps such as SmartGit to pick it up."
