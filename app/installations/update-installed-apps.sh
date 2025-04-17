#!/bin/bash

# Function to clean up and return
cleanup_and_return() {
    local return_code=$1
    enable_sleep
    return $return_code
}

status "Checking for available updates..."
disable_sleep

# Update package databases
status "Updating package databases..."
if ! sudo pacman -Sy --noconfirm --noprogressbar; then
    status "Error updating package databases. Please check your internet connection or run 'sudo pacman -Sy' manually to see detailed errors."
    cleanup_and_return 1
fi

# Get list of repo packages to update
repo_updates=$(pacman -Qu 2>/dev/null || echo "")
repo_count=$(echo "$repo_updates" | grep -v "^$" | wc -l)

# Get list of AUR packages to update
aur_updates=""
aur_count=0
if command -v yay >/dev/null 2>&1; then
    aur_updates=$(yay -Qua 2>/dev/null || echo "")
    aur_count=$(echo "$aur_updates" | grep -v "^$" | wc -l)
fi

total_count=$((repo_count + aur_count))

if [ "$total_count" -eq 0 ]; then
    status "No updates available. Your system is up to date."
    cleanup_and_return 0
    return 0  # Ensure script execution stops here
fi

# Create a summary of updates
status "Found $total_count package(s) that can be updated"

# Format and display the updates
if [ "$repo_count" -gt 0 ]; then
    echo "System repository updates ($repo_count):"
    echo "$repo_updates" | sort | awk '{print "  • " $1 " (" $2 " → " $4 ")"}'
    echo ""
fi

if [ "$aur_count" -gt 0 ]; then
    echo "AUR updates ($aur_count):"
    echo "$aur_updates" | sort | awk -F' ' '{print "  • " $1 " (" $2 " → " $4 ")"}'
    echo ""
fi

# Ask for confirmation
if ! gum confirm "Do you want to proceed with the updates?"; then
    status "Update cancelled."
    cleanup_and_return 0
fi

# Perform the update
status "Updating installed packages..."
if [ "$repo_count" -gt 0 ]; then
    status "Updating system packages..."
    sudo pacman -Su --noconfirm --noprogressbar
fi

if [ "$aur_count" -gt 0 ]; then
    status "Updating AUR packages..."
    yay -Sua --noconfirm --noprogressbar
fi

status "System update completed."
cleanup_and_return 0
