#!/bin/bash
set -e

PACMAN_CONF="/etc/pacman.conf"
MARKER="# WIREPLUMBER-IGNORE-START"
MARKER_END="# WIREPLUMBER-IGNORE-END"

if grep -q "$MARKER" "$PACMAN_CONF" 2>/dev/null; then
    status "Removing WirePlumber IgnorePkg workaround from pacman.conf..."
    sudo sed -i "/$MARKER/,/$MARKER_END/d" "$PACMAN_CONF"
else
    status "WirePlumber IgnorePkg workaround is not active."
fi

if pacman -Q wireplumber >/dev/null 2>&1; then
    current_version=$(pacman -Q wireplumber | awk '{print $2}' | sed 's/-.*$//')
else
    status "WirePlumber is not installed, skipping package cleanup."
    return 0
fi

if [[ "$current_version" == "0.5.12" ]]; then
    status "WirePlumber 0.5.12 detected, upgrading to the repo version..."
    sudo pacman -S --noconfirm --noprogressbar --quiet wireplumber libwireplumber
    systemctl --user restart wireplumber.service 2>/dev/null || true
    status "WirePlumber upgraded and service restarted."
else
    status "WirePlumber version is $current_version, no forced upgrade needed."
fi
