#!/bin/bash
set -e

if [[ "$XDG_CURRENT_DESKTOP" != *"GNOME"* ]]; then
    status "Skipping Clipboard Indicator extension installation as you are not running GNOME."
    exit 0
fi

if gnome-extensions list | grep -q "clipboard-indicator@tudmotu.com"; then
    status "Clipboard indicator extension is already installed."
    exit 0
fi

if gum confirm "Would you like to install the GNOME Clipboard Indicator extension?"; then
    gext install clipboard-indicator@tudmotu.com

    status "Clipboard Indicator extension installed successfully."
fi
