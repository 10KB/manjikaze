#!/bin/bash
#
# Block wireplumber updates in pacman until the GNOME fix is released
#
# See: https://gitlab.gnome.org/GNOME/libgnome-volume-control/-/merge_requests/31
#

set -e

PACMAN_CONF="/etc/pacman.conf"
BACKUP_FILE="/etc/pacman.conf.pre-wireplumber-ignore"
IGNORE_LINE="IgnorePkg = wireplumber libwireplumber"
MARKER="# WIREPLUMBER-IGNORE-START"
MARKER_END="# WIREPLUMBER-IGNORE-END"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (sudo)."
   exit 1
fi

# Check if already applied
if grep -q "$MARKER" "$PACMAN_CONF"; then
    echo "WirePlumber ignore is already active in $PACMAN_CONF"
    exit 0
fi

# Create backup
cp "$PACMAN_CONF" "$BACKUP_FILE"
echo "Backup created: $BACKUP_FILE"

# Add IgnorePkg after [options] section
sed -i "/^\[options\]/a\\
$MARKER\\
$IGNORE_LINE\\
$MARKER_END" "$PACMAN_CONF"

echo "✓ WirePlumber updates will now be ignored."
echo ""
echo "During system updates you will see:"
echo "  warning: wireplumber: ignoring package upgrade (0.5.12-1 => ...)"
echo ""
echo "Run './restore-wireplumber-updates.sh' to undo this."
