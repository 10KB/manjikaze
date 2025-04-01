#!/bin/bash
set -e

# Migration to remove yay AUR helper as we now use pamac

source "$MANJIKAZE_DIR/lib/common.sh"

status "Checking if yay is installed..."
if is_installed "yay"; then
    status "Removing yay package..."
    # Use pamac remove, it will ask for sudo if needed
    if pamac remove --no-confirm yay; then
        status "yay removed successfully."
    else
        status "Failed to remove yay. Please remove it manually using 'pamac remove yay'"
        exit 1 # Indicate failure
    fi
else
    status "yay is not installed. Skipping removal."
fi