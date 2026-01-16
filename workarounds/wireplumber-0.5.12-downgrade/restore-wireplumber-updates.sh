#!/bin/bash
#
# Restore wireplumber updates in pacman after the GNOME fix is released
#
# Use this script once gnome-shell contains the fix from:
# https://gitlab.gnome.org/GNOME/libgnome-volume-control/-/merge_requests/31
#

set -e

PACMAN_CONF="/etc/pacman.conf"
MARKER="# WIREPLUMBER-IGNORE-START"
MARKER_END="# WIREPLUMBER-IGNORE-END"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (sudo)."
   exit 1
fi

# Check if marker exists
if ! grep -q "$MARKER" "$PACMAN_CONF"; then
    echo "No wireplumber ignore found in $PACMAN_CONF"
    echo "Nothing to restore."
    exit 0
fi

# Remove the ignore block
sed -i "/$MARKER/,/$MARKER_END/d" "$PACMAN_CONF"

echo "✓ WirePlumber updates have been restored."
echo ""
echo "You can now update to the latest version with:"
echo "  sudo pacman -Syu"
