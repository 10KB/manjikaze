#!/bin/bash
set -e

# A desktop session and its services start from a login shell, not from .zshrc where mise is
# activated, so they didn't find tools installed with mise, such as scw.

if ! command -v mise &> /dev/null; then
    return 0
fi

sudo install -Dm644 "$MANJIKAZE_DIR/configs/profile.d/manjikaze-mise.sh" /etc/profile.d/manjikaze-mise.sh

# Services started from now on get the shims in this session already; running apps need a new login.
shims="${XDG_DATA_HOME:-$HOME/.local/share}/mise/shims"
session_path=$(systemctl --user show-environment 2> /dev/null | sed -n 's/^PATH=//p')
if [[ -n $session_path && ":$session_path:" != *":$shims:"* ]]; then
    systemctl --user set-environment PATH="$session_path:$shims" || true
fi

status "Log out and back in, so every desktop app finds the tools installed with mise."
