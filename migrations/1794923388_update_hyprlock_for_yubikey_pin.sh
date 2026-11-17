#!/bin/bash
set -e

# The lock screen no longer unlocks with Enter on an empty field and a touch of the YubiKey. It now
# asks for the YubiKey's PIN, and an empty PIN could cost one of the YubiKey's PIN attempts.

hyprlock_conf="$HOME/.config/hypr/hyprlock.conf"

if [[ ! -f $hyprlock_conf ]]; then
    status "No hyprlock.conf to update, skipping."
    return 0
fi

sed -i 's|^\(\s*\)ignore_empty_input = false\s*$|\1ignore_empty_input = true|' "$hyprlock_conf"
sed -i 's|^\(\s*\)placeholder_text = <span foreground="##8b98a5">Password for \$USER (or Enter with YubiKey)</span>\s*$|\1placeholder_text = <span foreground="##8b98a5">Password for $USER</span>|' "$hyprlock_conf"
status "The lock screen no longer offers to unlock with Enter and a touch of the YubiKey."
