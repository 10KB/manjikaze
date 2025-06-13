#!/bin/bash
set -e

if [[ "$XDG_CURRENT_DESKTOP" != *"GNOME"* ]]; then
    status "Skipping gnome-extensions-cli migration as you are not running GNOME."
    exit 0
fi

# Check if gnome-extensions-cli is installed via pacman/yay
if pacman -Q "gnome-extensions-cli" &>/dev/null; then
    status "Found gnome-extensions-cli AUR package, migrating to pip installation..."

    uninstall_package "gnome-extensions-cli" "aur"

    status "Installing gnome-extensions-cli via pip..."
    if ! pip3 install --user --upgrade gnome-extensions-cli; then
        status "Error: Failed to install gnome-extensions-cli via pip."
        status "Please try installing it manually: 'pip3 install --user --upgrade gnome-extensions-cli'"
        exit 1
    fi

    status "gnome-extensions-cli migration completed successfully!"
else
    status "gnome-extensions-cli AUR package not found. No migration needed."
fi
