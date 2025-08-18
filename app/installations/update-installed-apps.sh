#!/bin/bash

REBOOT_PATTERNS=(
    "firmware"    # For packages like linux-firmware, or other firmware blobs
    "ucode"       # For microcode updates (amd-ucode, intel-ucode)
    "dbus"
    "glibc"
    "systemd"
    "gnutls"
    "openssl"
    "mesa"        # Graphics stack
    "nvidia"      # NVIDIA drivers
    "xf86-video-" # Common prefix for Xorg video drivers
    "docker"
    "containerd"
    "runc"
    "virtualbox"  # Virtualization software often has kernel modules
    "vmware"      # Virtualization software often has kernel modules
    "qemu"
    "libvirt"
    "kernel"      # Catch any explicit 'kernel' named packages if not 'linux*'
)

# Function to clean up and return
cleanup_and_return() {
    local return_code=$1
    enable_sleep
    return $return_code
}

# Source Cursor installation functions
source "$MANJIKAZE_DIR/app/installations/essential/cursor.sh"

status "Checking for available updates..."
disable_sleep

reboot_suggested=false
reboot_trigger_message=""

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

# Check for Cursor updates
cursor_update_available=false
cursor_version_info=""
if [ -d ~/.local/share/cursor ]; then
    status "Checking for Cursor updates..."
    installed_version=$(get_cursor_installed_version)

    if [[ -n "$installed_version" ]]; then
        latest_url=$(get_cursor_download_url)
        latest_version=$(echo "$latest_url" | grep -oP 'Cursor-\K[0-9]+\.[0-9]+\.[0-9]+' || echo "")

        if [[ -n "$latest_version" && "$installed_version" != "$latest_version" ]]; then
            cursor_update_available=true
            cursor_version_info="$installed_version → $latest_version"
        fi
    fi
fi

total_count=$((repo_count + aur_count))
if [ "$cursor_update_available" = true ]; then
    total_count=$((total_count + 1))
fi

if [ "$total_count" -eq 0 ]; then
    status "No updates available. Your system is up to date."
    cleanup_and_return 0
    return 0  # Ensure script execution stops here
fi

# Check for packages that require a reboot
all_updates_list_names=""
if [ "$repo_count" -gt 0 ]; then
    repo_package_names=$(echo "$repo_updates" | awk '{print $1}' | tr '\n' ' ')
    all_updates_list_names="${all_updates_list_names}${repo_package_names}"
fi
if [ "$aur_count" -gt 0 ]; then
    aur_package_names=$(echo "$aur_updates" | awk '{print $1}' | tr '\n' ' ')
    all_updates_list_names="${all_updates_list_names}${aur_package_names}"
fi

if [ -n "$all_updates_list_names" ]; then
    for pkg_name in $all_updates_list_names; do
        pkg_name_lower="${pkg_name,,}"

        if [[ "$pkg_name_lower" == linux* ]]; then
            reboot_suggested=true
            reboot_trigger_message="An update to a kernel package ('$pkg_name') was found."
            break
        fi

        for pattern in "${REBOOT_PATTERNS[@]}"; do
            pattern_lower="${pattern,,}"
            if [[ "$pkg_name_lower" == *"$pattern_lower"* ]]; then
                reboot_suggested=true
                reboot_trigger_message="An update to '$pkg_name' (matches general pattern '$pattern') was found."
                break
            fi
        done

        if [ "$reboot_suggested" = true ]; then
            break
        fi
    done
fi

status "Found $total_count package(s) that can be updated"

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

if [ "$cursor_update_available" = true ]; then
    echo "Application updates:"
    echo "  • Cursor ($cursor_version_info)"
    echo ""
fi

if [ "$reboot_suggested" = true ]; then
    echo ""
    status "$reboot_trigger_message"
    status "IMPORTANT: This update may require a system reboot to apply fully and ensure stability."
    echo "             It's recommended to reboot after the update completes."
    echo ""
fi

if ! gum confirm "Do you want to proceed with the updates?"; then
    status "Update cancelled."
    cleanup_and_return 0
fi

# Handle specific known package conflicts (e.g. Node.js LTS transitions)
if echo "$repo_updates" | grep -q "^nodejs-lts-jod " && pacman -Qqe | grep -q "^nodejs-lts-iron$"; then
    status "Removing obsolete nodejs-lts-iron package to resolve conflict with nodejs-lts-jod..."
    # Cascade remove to automatically uninstall packages that strictly depend on nodejs-lts-iron
    sudo pacman -Rcns --noconfirm nodejs-lts-iron
fi

status "Updating installed packages..."
if [ "$repo_count" -gt 0 ]; then
    status "Updating system packages..."
    sudo pacman -Su --noconfirm --noprogressbar
fi

if [ "$aur_count" -gt 0 ]; then
    status "Updating AUR packages..."
    yay -Sua --noconfirm --noprogressbar
fi

# Update Cursor if available
if [ "$cursor_update_available" = true ]; then
    status "Updating Cursor..."
    download_cursor_appimage "$latest_url"
    install_cursor_from_appimage
    status "Cursor update complete!"
fi

status "System update completed."

if [ "$reboot_suggested" = true ]; then
    status "Reminder: $reboot_trigger_message"
    status "A system reboot is highly recommended to apply these changes fully and ensure system stability."
    if gum confirm "Do you want to reboot the system now?"; then
        status "Rebooting system..."
        # Attempt to re-enable sleep if disable_sleep was used, though reboot will reset states
        if type enable_sleep &>/dev/null; then
            enable_sleep
        fi
        sudo reboot
    else
        status "Reboot cancelled by user. Please remember to reboot your system soon."
    fi
fi

cleanup_and_return 0
