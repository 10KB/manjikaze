#!/bin/bash
set -e

# Removing the YubiKey sent several lock requests at once, which started several hyprlocks. The
# extra ones hung, and after that locking the screen did nothing until the next login.

hypridle_conf="$HOME/.config/hypr/hypridle.conf"

if ! grep -qs '^\s*lock_cmd = pidof hyprlock || hyprlock\s*$' "$hypridle_conf"; then
    status "hypridle.conf has no default lock command to update, skipping."
    return 0
fi

sed -i 's#^\(\s*\)lock_cmd = pidof hyprlock || hyprlock\s*$#\1lock_cmd = flock -no "$XDG_RUNTIME_DIR/manjikaze-hyprlock.lock" hyprlock#' "$hypridle_conf"

# Restarting hypridle also ends hung hyprlocks it started. This runs from an unlocked session, so
# none of them is the active lock screen.
systemctl --user try-restart hypridle.service 2>/dev/null || true
status "The lock screen now starts once, also when the YubiKey is removed."
