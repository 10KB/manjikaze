#!/bin/bash
set -e

ALACRITTY_CONFIG="$HOME/.config/alacritty/alacritty.toml"

if [ -f "$ALACRITTY_CONFIG" ] && grep -q '^program = "zellij"$' "$ALACRITTY_CONFIG"; then
    status "Removing Zellij as the default Alacritty shell..."
    sed -i '/^\[terminal\.shell\]$/{N;/\nprogram = "zellij"$/d}' "$ALACRITTY_CONFIG"
else
    status "Alacritty does not start Zellij by default, skipping config change."
fi

if command -v alacritty &> /dev/null; then
    add_gnome_shortcut "alacritty" "Alacritty" "alacritty" "<Super>Return"

    if command -v zellij &> /dev/null; then
        add_gnome_shortcut "zellij" "Zellij" "alacritty -e zellij" "<Super><Alt>Return"
    fi
fi
