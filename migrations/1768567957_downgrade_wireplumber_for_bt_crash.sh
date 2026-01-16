#!/bin/bash
set -e

# WirePlumber 0.5.13 Bluetooth profile autoswitch causes GNOME crashes
# when switching from A2DP to HSP/HFP (handsfree) profile.
#
# See: https://gitlab.gnome.org/GNOME/libgnome-volume-control/-/merge_requests/31
# See: https://gitlab.freedesktop.org/pipewire/wireplumber/-/merge_requests/776

PACMAN_CONF="/etc/pacman.conf"
MARKER="# WIREPLUMBER-IGNORE-START"
MARKER_END="# WIREPLUMBER-IGNORE-END"
IGNORE_LINE="IgnorePkg = wireplumber libwireplumber"

WORKAROUND_DIR="$MANJIKAZE_DIR/workarounds/wireplumber-0.5.12-downgrade"

status "Applying WirePlumber 0.5.12 downgrade workaround for Bluetooth audio crash..."

# Check current wireplumber version
current_version=$(pacman -Q wireplumber 2>/dev/null | awk '{print $2}' | sed 's/-.*$//')

if [[ "$current_version" == "0.5.13" ]]; then
    status "WirePlumber 0.5.13 detected, downgrading to 0.5.12..."

    # Check if workaround packages exist
    if [[ ! -f "$WORKAROUND_DIR/wireplumber-0.5.12-1-x86_64.pkg.tar.zst" ]]; then
        status "ERROR: Workaround packages not found in $WORKAROUND_DIR"
        status "Please ensure the workaround packages are present."
        exit 1
    fi

    # Downgrade packages
    sudo pacman -U --noconfirm \
        "$WORKAROUND_DIR/libwireplumber-0.5.12-1-x86_64.pkg.tar.zst" \
        "$WORKAROUND_DIR/wireplumber-0.5.12-1-x86_64.pkg.tar.zst"

    status "WirePlumber downgraded to 0.5.12"

    # Restart wireplumber
    systemctl --user restart wireplumber.service 2>/dev/null || true
    status "WirePlumber service restarted"
else
    status "WirePlumber version is $current_version (not 0.5.13), no downgrade needed."
fi

# Add IgnorePkg to pacman.conf if not already present
if grep -q "$MARKER" "$PACMAN_CONF"; then
    status "WirePlumber update ignore is already active in pacman.conf"
else
    status "Adding WirePlumber to IgnorePkg in pacman.conf..."

    # Create backup
    sudo cp "$PACMAN_CONF" "$PACMAN_CONF.pre-wireplumber-ignore-$(date +%s)"

    # Add IgnorePkg after [options] section
    sudo sed -i "/^\[options\]/a\\
$MARKER\\
$IGNORE_LINE\\
$MARKER_END" "$PACMAN_CONF"

    status "WirePlumber updates will now be ignored during system updates."
fi

status ""
status "Workaround applied successfully!"
status ""
status "Note: When the GNOME fix is released (MR #31), a follow-up migration"
status "will remove this workaround automatically."
