#!/bin/bash
set -e

status "Checking for Dropbox to install libappindicator dependencies..."

if is_installed "dropbox"; then
    status "Dropbox is installed, ensuring libappindicator dependencies are present..."
    install_package "libappindicator-gtk2" "aur"
    install_package "libappindicator-gtk3" "aur"
else
    status "Dropbox is not installed, skipping."
fi
