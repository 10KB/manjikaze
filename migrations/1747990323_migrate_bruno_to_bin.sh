#!/bin/bash
set -e

status "Migrating Bruno from bruno to bruno-bin (if installed)..."

# Check if old bruno package is installed (not bruno-bin)
if pacman -Q "bruno" 2>/dev/null | grep -q "^bruno "; then
    status "Found old bruno package, migrating to bruno-bin..."

    uninstall_package "bruno" aur
    uninstall_package "electron33" aur

    source "$MANJIKAZE_DIR/app/installations/recommended/bruno.sh"

    status "Bruno migration completed successfully!"
fi
