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

# Function to refresh package signing keys
# This fixes "signature is unknown trust" errors that occur when keyring
# packages are outdated or the local keyring hasn't been refreshed
refresh_keyrings() {
    status "Refreshing package signing keys..."
    if ! sudo pacman -S --needed --noconfirm archlinux-keyring manjaro-keyring 2>/dev/null; then
        # If standard update fails, try a full keyring refresh
        status "Standard keyring update failed, performing full keyring refresh..."
        sudo pacman-key --init
        sudo pacman-key --populate archlinux manjaro
    else
        sudo pacman-key --populate archlinux manjaro 2>/dev/null || true
    fi
}

resolve_known_repo_transitions() {
    if pacman -Qq geocode-glib-common >/dev/null 2>&1 &&
        pacman -Si geocode-glib 2>/dev/null | grep -Fq "geocode-glib-common<=3.26.4-5"; then
        status "Resolving geocode-glib package transition..."
        sudo pacman -S --needed --noconfirm --noprogressbar --quiet --ask 4 geocode-glib
    fi

    if echo "$repo_updates" | grep -q "^nodejs-lts-jod " && pacman -Qqe | grep -q "^nodejs-lts-iron$"; then
        status "Removing obsolete nodejs-lts-iron package to resolve conflict with nodejs-lts-jod..."
        # Cascade remove to automatically uninstall packages that strictly depend on nodejs-lts-iron
        sudo pacman -Rcns --noconfirm nodejs-lts-iron
    fi
}

refresh_aur_updates() {
    aur_updates=""
    aur_count=0
    if command -v yay >/dev/null 2>&1; then
        aur_updates=$(yay -Qua 2>/dev/null || echo "")
        aur_count=$(echo "$aur_updates" | grep -v "^$" | wc -l)
    fi
}

ulauncher_webkit_transition_needed() {
    if pacman -Qq ulauncher >/dev/null 2>&1 &&
        pacman -Qi ulauncher 2>/dev/null | grep -Eq '(^|[[:space:]])webkit2gtk([[:space:]]|$)' &&
        yay -Si ulauncher 2>/dev/null | grep -Eq '(^|[[:space:]])webkit2gtk-4\.1([[:space:]]|$)'; then
        return 0
    fi

    return 1
}

filter_known_aur_transition_updates() {
    known_aur_transition_count=0
    known_aur_transition_descriptions=()

    if ulauncher_webkit_transition_needed; then
        known_aur_transition_count=1
        known_aur_transition_descriptions+=("ulauncher (webkit2gtk → webkit2gtk-4.1)")
        aur_updates=$(echo "$aur_updates" | grep -v "^webkit2gtk " || true)
        aur_count=$(echo "$aur_updates" | grep -v "^$" | wc -l)
    fi
}

resolve_known_aur_transitions() {
    if ulauncher_webkit_transition_needed; then
        status "Reinstalling ulauncher to switch from webkit2gtk to webkit2gtk-4.1..."
        PATH=/usr/bin:$PATH yay -S --rebuild --redownload --noconfirm --noprogressbar --quiet ulauncher

        if pacman -Qq webkit2gtk >/dev/null 2>&1 &&
            pacman -Qi webkit2gtk 2>/dev/null | grep -q "^Required By     : None$"; then
            status "Removing obsolete AUR webkit2gtk package..."
            sudo pacman -Rns --noconfirm --noprogressbar webkit2gtk
        fi
    fi
}

# Source Cursor installation functions
source "$MANJIKAZE_DIR/app/installations/essential/cursor.sh"

# Print a beautiful header
gum style \
    --foreground 99 \
    --border double \
    --border-foreground 99 \
    --align center \
    --width 50 \
    --margin "1 0" \
    --padding "0 2" \
    "Manjikaze Update Wizard"

status "Checking for available updates..."
disable_sleep

reboot_suggested=false
reboot_trigger_message=""

# Update package databases
status "Updating package databases..."
if ! sudo pacman -Sy --noconfirm --noprogressbar; then
    # Database sync failed, might be a keyring issue - try refreshing keyrings first
    refresh_keyrings
    status "Retrying database sync..."
    if ! sudo pacman -Sy --noconfirm --noprogressbar; then
        status "Error updating package databases. Please check your internet connection or run 'sudo pacman -Sy' manually to see detailed errors."
        cleanup_and_return 1
    fi
fi

# Get list of repo packages to update, filtering out ignored packages
# pacman -Qu marks ignored packages with [ignored], so we filter those out
repo_updates=$(pacman -Qu 2>/dev/null | grep -v '\[ignored\]' || echo "")
repo_count=$(echo "$repo_updates" | grep -v "^$" | wc -l)

# Get list of AUR packages to update
refresh_aur_updates
filter_known_aur_transition_updates

# Check for Cursor updates
cursor_update_available=false
cursor_version_info=""
if [ -d ~/.local/share/cursor ]; then
    status "Checking for Cursor updates..."
    installed_version=$(get_cursor_installed_version)
    latest_version=$(get_cursor_latest_stable_version)

    if [[ -n "$installed_version" && -n "$latest_version" && "$installed_version" != "$latest_version" ]]; then
        cursor_update_available=true
        cursor_version_info="$installed_version → $latest_version"
    fi
fi

total_count=$((repo_count + aur_count + known_aur_transition_count))
if [ "$cursor_update_available" = true ]; then
    total_count=$((total_count + 1))
fi

if [ "$total_count" -eq 0 ]; then
    status "No updates available. Your system is up to date."
    cleanup_and_return 0
    return 0  # Ensure script execution stops here
fi

# Print current overview of updates
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

if [ "$known_aur_transition_count" -gt 0 ]; then
    echo "AUR package transitions ($known_aur_transition_count):"
    printf '%s\n' "${known_aur_transition_descriptions[@]}" | sort | awk '{print "  • " $0}'
    echo ""
fi

if [ "$cursor_update_available" = true ]; then
    echo "Application updates:"
    echo "  • Cursor ($cursor_version_info)"
    echo ""
fi

# Step-by-step interactive selections
update_repo=false
if [ "$repo_count" -gt 0 ]; then
    if gum confirm "Update system repository packages? ($repo_count packages available)"; then
        update_repo=true
    fi
fi

apply_transitions=false
if [ "$known_aur_transition_count" -gt 0 ]; then
    if gum confirm "Apply AUR package transitions? (${known_aur_transition_descriptions[*]})"; then
        apply_transitions=true
    fi
fi

selected_aur_packages=()
if [ "$aur_count" -gt 0 ]; then
    status "Select AUR packages to update (unselected by default):"
    
    aur_options=()
    while read -r line; do
        [ -z "$line" ] && continue
        pkg_name=$(echo "$line" | awk '{print $1}')
        curr_ver=$(echo "$line" | awk '{print $2}')
        new_ver=$(echo "$line" | awk '{print $4}')
        aur_options+=("$pkg_name ($curr_ver -> $new_ver)")
    done <<< "$aur_updates"
    
    selected_options=$(printf "%s\n" "${aur_options[@]}" | gum choose --no-limit --header="Space to select, Enter to confirm")
    
    if [ -n "$selected_options" ]; then
        while read -r opt; do
            [ -z "$opt" ] && continue
            pkg=$(echo "$opt" | awk '{print $1}')
            selected_aur_packages+=("$pkg")
        done <<< "$selected_options"
    fi
fi

update_cursor=false
if [ "$cursor_update_available" = true ]; then
    if gum confirm "Update Cursor editor? ($cursor_version_info)"; then
        update_cursor=true
    fi
fi

# Check if anything was selected
selected_count=0
if [ "$update_repo" = true ]; then
    selected_count=$((selected_count + repo_count))
fi
if [ "$apply_transitions" = true ]; then
    selected_count=$((selected_count + known_aur_transition_count))
fi
selected_count=$((selected_count + ${#selected_aur_packages[@]}))
if [ "$update_cursor" = true ]; then
    selected_count=$((selected_count + 1))
fi

if [ "$selected_count" -eq 0 ]; then
    status "No updates selected. Exiting."
    cleanup_and_return 0
    return 0
fi

# Check if selected packages require a reboot
reboot_suggested=false
reboot_trigger_message=""
selected_packages_for_reboot_check=""

if [ "$update_repo" = true ]; then
    selected_packages_for_reboot_check="${selected_packages_for_reboot_check} $(echo "$repo_updates" | awk '{print $1}' | tr '\n' ' ')"
fi
if [ ${#selected_aur_packages[@]} -gt 0 ]; then
    selected_packages_for_reboot_check="${selected_packages_for_reboot_check} ${selected_aur_packages[*]}"
fi

if [ -n "$selected_packages_for_reboot_check" ]; then
    for pkg_name in $selected_packages_for_reboot_check; do
        pkg_name_lower="${pkg_name,,}"

        if [[ "$pkg_name_lower" == linux* ]]; then
            reboot_suggested=true
            reboot_trigger_message="An update to a kernel package ('$pkg_name') was selected."
            break
        fi

        for pattern in "${REBOOT_PATTERNS[@]}"; do
            pattern_lower="${pattern,,}"
            if [[ "$pkg_name_lower" == *"$pattern_lower"* ]]; then
                reboot_suggested=true
                reboot_trigger_message="An update to '$pkg_name' (matches general pattern '$pattern') was selected."
                break
            fi
        done

        if [ "$reboot_suggested" = true ]; then
            break
        fi
    done
fi

# Show summary of selected updates
echo ""
gum style --foreground 99 --bold "Selected Updates Summary:"
if [ "$update_repo" = true ]; then
    echo "  • System repository updates ($repo_count packages)"
fi
if [ "$apply_transitions" = true ]; then
    echo "  • AUR transitions: ${known_aur_transition_descriptions[*]}"
fi
if [ ${#selected_aur_packages[@]} -gt 0 ]; then
    echo "  • AUR packages to update (${#selected_aur_packages[@]}):"
    for pkg in "${selected_aur_packages[@]}"; do
        echo "    - $pkg"
    done
fi
if [ "$update_cursor" = true ]; then
    echo "  • Application: Cursor ($cursor_version_info)"
fi

if [ "$reboot_suggested" = true ]; then
    echo ""
    status "$reboot_trigger_message"
    status "IMPORTANT: This update may require a system reboot to apply fully and ensure stability."
    echo "             It's recommended to reboot after the update completes."
fi
echo ""

if ! gum confirm "Proceed with the selected updates?"; then
    status "Update cancelled."
    cleanup_and_return 0
    return 0
fi

# Execution phase
status "Updating installed packages..."

if [ "$update_repo" = true ]; then
    resolve_known_repo_transitions
    
    # Update keyrings first if there are keyring updates pending
    keyring_updates=$(echo "$repo_updates" | grep -E "keyring" || true)
    if [ -n "$keyring_updates" ]; then
        refresh_keyrings
    fi

    status "Updating system packages..."
    if ! sudo pacman -Su --noconfirm --noprogressbar; then
        # If update fails, try refreshing keyring and retrying
        refresh_keyrings
        status "Retrying system update..."
        sudo pacman -Su --noconfirm --noprogressbar
    fi
fi

if [ "$apply_transitions" = true ]; then
    resolve_known_aur_transitions
fi

if [ ${#selected_aur_packages[@]} -gt 0 ]; then
    status "Updating AUR packages..."
    failed_packages=()

    for pkg in "${selected_aur_packages[@]}"; do
        status "Updating package $pkg..."
        # PATH override ensures system tools like brz use system Python for building AUR packages
        if PATH=/usr/bin:$PATH yay -S --needed --noconfirm --noprogressbar "$pkg"; then
            status "Updating package $pkg succeeded."
        else
            status "Updating package $pkg failed."
            failed_packages+=("$pkg")
        fi
    done

    if [ ${#failed_packages[@]} -gt 0 ]; then
        status "Failed to install the following packages. Manual intervention is required: [${failed_packages[*]}]"
    fi
fi

# Sync mise runtimes if mise is installed
if command -v mise &>/dev/null; then
    status "Syncing mise runtimes..."
    mise install
fi

# Update Cursor if selected
if [ "$update_cursor" = true ]; then
    cursor_track=$(get_cursor_release_track)
    status "Updating Cursor..."
    install_stable_signed
    # Nightly doesn't have a remote version API, so update alongside stable when both tracks are active
    if [[ "$cursor_track" == "stable+nightly" ]]; then
        install_nightly_appimage
    fi
    status "Cursor update complete!"
fi

# Clean up orphan packages (dependencies no longer required by any installed package)
orphans=$(pacman -Qdtq 2>/dev/null || echo "")
if [ -n "$orphans" ]; then
    orphan_count=$(echo "$orphans" | wc -l)
    status "Found $orphan_count orphan package(s) to remove..."
    echo "$orphans" | xargs sudo pacman -Rns --noconfirm --noprogressbar
    status "Orphan packages removed."
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
