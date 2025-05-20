#!/bin/bash
set -e

if ! command -v cursor &> /dev/null; then
    status "Cursor is not installed. Skipping migration."
    return 0
fi

if gum confirm $'Would you like to convert your Cursor installation to an extracted AppImage?\nNote: This could result in a loss of your chat history and settings.'; then
    status "Removing existing Cursor installation..."
    yay -Rns --noconfirm --noprogressbar cursor

    status "Installing Cursor as an extracted AppImage..."
    source "$MANJIKAZE_DIR/app/installations/essential/cursor.sh"

    install_cursor
fi