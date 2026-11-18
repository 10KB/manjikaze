#!/bin/bash
set -e

# Migration 1795007645 put mise's shims on the PATH of the desktop session. A shim takes its
# version from the mise.toml or .tool-versions of the directory it runs in, so a project could
# decide what runs on the host. The tools now come from links in ~/.local/bin instead.

if [[ -f /etc/profile.d/manjikaze-mise.sh ]]; then
    sudo rm /etc/profile.d/manjikaze-mise.sh
fi

shims="${XDG_DATA_HOME:-$HOME/.local/share}/mise/shims"
session_path=$(systemctl --user show-environment 2> /dev/null | sed -n 's/^PATH=//p')
if [[ ":$session_path:" == *":$shims:"* ]]; then
    session_path=$(printf '%s\n' "$session_path" | tr ':' '\n' | grep -vxF "$shims" | paste -sd: -)
    systemctl --user set-environment PATH="$session_path" || true
    status "Log out and back in, so apps that started with mise's shims on their PATH lose them."
fi
