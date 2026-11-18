#!/bin/bash

source "$MANJIKAZE_DIR/lib/update.sh"
source "$MANJIKAZE_DIR/app/installations/optional/cursor.sh"

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
        yay_system -S --rebuild --redownload --noconfirm --noprogressbar --quiet ulauncher

        if pacman -Qq webkit2gtk >/dev/null 2>&1 &&
            pacman -Qi webkit2gtk 2>/dev/null | grep -q "^Required By     : None$"; then
            status "Removing obsolete AUR webkit2gtk package..."
            sudo pacman -Rns --noconfirm --noprogressbar webkit2gtk
        fi
    fi
}

# Sets repo_updates, the AUR updates and transitions, the Cursor update, the missing mise tools
# and total_count.
find_updates() {
    status "Checking for available updates..."
    if ! repo_updates=$(list_repo_updates); then
        status "Could not check for updates. Check your internet connection, or run 'checkupdates' to see the error."
        return 1
    fi
    repo_count=$(echo "$repo_updates" | grep -v "^$" | wc -l)

    refresh_aur_updates
    filter_known_aur_transition_updates

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

    # Tool versions the global mise configuration asks for but that aren't installed, such as a
    # version that a Manjikaze update pinned.
    mise_missing=""
    mise_count=0
    if command -v mise &>/dev/null; then
        refresh_mise_tools
        mise_missing=$(cd "$HOME" && mise ls --missing --global --json 2>/dev/null |
            jq -r 'to_entries[] | .key as $tool | .value[] | "\($tool) \(.version)"' || true)
        mise_count=$(echo "$mise_missing" | grep -vc '^$' || true)
    fi

    total_count=$((repo_count + aur_count + known_aur_transition_count + mise_count))
    if [ "$cursor_update_available" = true ]; then
        total_count=$((total_count + 1))
    fi
}

show_updates() {
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

    if [ "$mise_count" -gt 0 ]; then
        echo "mise tools ($mise_count):"
        echo "$mise_missing" | sort | awk '{print "  • " $1 " (" $2 ")"}'
        echo ""
    fi
}

# Sets update_repo, apply_transitions, selected_aur_packages, update_cursor and selected_count.
choose_updates() {
    update_repo=false
    if [ "$repo_count" -gt 0 ]; then
        if update_confirm "Update system repository packages? ($repo_count packages available)"; then
            update_repo=true
        fi
    fi

    # AUR packages build against the system packages. Building them against packages that have
    # an update waiting would need the newer versions: a partial upgrade.
    local aur_allowed=true
    if [ "$repo_count" -gt 0 ] && [ "$update_repo" = false ] &&
        [ $((aur_count + known_aur_transition_count)) -gt 0 ]; then
        aur_allowed=false
        status "Skipping AUR updates: they are built against the system packages, so those have to be updated first."
    fi

    apply_transitions=false
    if [ "$aur_allowed" = true ] && [ "$known_aur_transition_count" -gt 0 ]; then
        if update_confirm "Apply AUR package transitions? (${known_aur_transition_descriptions[*]})"; then
            apply_transitions=true
        fi
    fi

    selected_aur_packages=()
    if [ "$aur_allowed" = true ] && [ "$aur_count" -gt 0 ] && update_unattended; then
        readarray -t selected_aur_packages < <(echo "$aur_updates" | awk 'NF {print $1}')
    elif [ "$aur_allowed" = true ] && [ "$aur_count" -gt 0 ]; then
        status "Select AUR packages to update (unselected by default):"

        local aur_options=() line pkg_name curr_ver new_ver selected_options opt
        while read -r line; do
            [ -z "$line" ] && continue
            pkg_name=$(echo "$line" | awk '{print $1}')
            curr_ver=$(echo "$line" | awk '{print $2}')
            new_ver=$(echo "$line" | awk '{print $4}')
            aur_options+=("$pkg_name ($curr_ver -> $new_ver)")
        done <<< "$aur_updates"

        # Gum 2 no longer toggles with Space (Bubble Tea reports it as "space", not " ").
        selected_options=$(printf "%s\n" "${aur_options[@]}" | gum choose --no-limit --show-help --header "x or Tab to select, Enter to confirm")

        if [ -n "$selected_options" ]; then
            while read -r opt; do
                [ -z "$opt" ] && continue
                selected_aur_packages+=("$(echo "$opt" | awk '{print $1}')")
            done <<< "$selected_options"
        fi
    fi

    update_cursor=false
    if [ "$cursor_update_available" = true ]; then
        if update_confirm "Update Cursor editor? ($cursor_version_info)"; then
            update_cursor=true
        fi
    fi

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
    # mise tools are always synced once the update proceeds.
    selected_count=$((selected_count + mise_count))
}

# Sets reboot_suggested and reboot_trigger_message from the names of the selected packages.
check_reboot_patterns() {
    reboot_suggested=false
    reboot_trigger_message=""
    local selected_packages_for_reboot_check="" pkg_name pkg_name_lower pattern pattern_lower

    if [ "$update_repo" = true ]; then
        selected_packages_for_reboot_check="${selected_packages_for_reboot_check} $(echo "$repo_updates" | awk '{print $1}' | tr '\n' ' ')"
    fi
    if [ ${#selected_aur_packages[@]} -gt 0 ]; then
        selected_packages_for_reboot_check="${selected_packages_for_reboot_check} ${selected_aur_packages[*]}"
    fi

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
}

show_selection() {
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
        local pkg
        for pkg in "${selected_aur_packages[@]}"; do
            echo "    - $pkg"
        done
    fi
    if [ "$update_cursor" = true ]; then
        echo "  • Application: Cursor ($cursor_version_info)"
    fi
    if [ "$mise_count" -gt 0 ]; then
        echo "  • mise tools ($mise_count)"
    fi

    if [ "$reboot_suggested" = true ]; then
        echo ""
        status "$reboot_trigger_message"
        status "IMPORTANT: This update may require a system reboot to apply fully and ensure stability."
        echo "             It's recommended to reboot after the update completes."
    fi
    echo ""
}

# The databases are synced right before the upgrade, so they are never newer than the packages
# for longer than this step takes.
update_system_packages() {
    status "Updating system packages..."
    if ! run_pacman_transaction -Sy --noconfirm --noprogressbar; then
        # A failed sync can be a keyring problem.
        refresh_keyrings
        status "Retrying the database sync..."
        run_pacman_transaction -Sy --noconfirm --noprogressbar || return 1
    fi

    resolve_known_repo_transitions

    # Update keyrings first if there are keyring updates pending
    if echo "$repo_updates" | grep -q "keyring"; then
        refresh_keyrings
    fi

    if ! run_pacman_transaction -Su --noconfirm --noprogressbar; then
        # If update fails, try refreshing keyring and retrying
        refresh_keyrings
        status "Retrying system update..."
        run_pacman_transaction -Su --noconfirm --noprogressbar || return 1
    fi
}

update_aur_packages() {
    if [ "$apply_transitions" = true ]; then
        resolve_known_aur_transitions
    fi

    if [ ${#selected_aur_packages[@]} -eq 0 ]; then
        return 0
    fi

    status "Updating AUR packages..."
    local failed_packages=() pkg
    for pkg in "${selected_aur_packages[@]}"; do
        status "Updating package $pkg..."
        if yay_system -S --needed --noconfirm --noprogressbar "$pkg"; then
            status "Updating package $pkg succeeded."
        else
            status "Updating package $pkg failed."
            failed_packages+=("$pkg")
        fi
    done

    if [ ${#failed_packages[@]} -gt 0 ]; then
        status "Failed to install the following packages. Manual intervention is required: [${failed_packages[*]}]"
        return 1
    fi
}

finish_update() {
    # Sync mise runtimes if mise is installed. The system upgrade may have brought a Manjikaze
    # package with newer pinned versions, so the managed files are refreshed again first.
    if command -v mise &>/dev/null; then
        status "Syncing mise runtimes..."
        refresh_mise_tools
        (cd "$HOME" && mise install) || status "Could not sync the mise runtimes."
        link_mise_tools
    fi

    if [ "$update_cursor" = true ]; then
        local cursor_track
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
    local orphans orphan_count
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
        if update_unattended; then
            status "This update ran unattended, so it doesn't reboot. Reboot when it suits you."
        elif gum confirm "Do you want to reboot the system now?"; then
            status "Rebooting system..."
            enable_sleep
            sudo reboot
        else
            status "Reboot cancelled by user. Please remember to reboot your system soon."
        fi
    fi
}

# Migrations ship with Manjikaze, which may itself be one of the system packages, and are written
# for the upgraded system. They run after the system packages and before the AUR packages.
run_update_migrations() {
    local options=()
    if update_unattended; then
        options=(--yes)
    fi

    if ! run_migrations "${options[@]}"; then
        status "Migrations finished with errors or were skipped."
        return 1
    fi
}

# The order is fixed: system packages, then migrations, then AUR packages and the rest.
run_update() {
    gum style \
        --foreground 99 \
        --border double \
        --border-foreground 99 \
        --align center \
        --width 50 \
        --margin "1 0" \
        --padding "0 2" \
        "Manjikaze Update Wizard"

    if ! update_has_free_space; then
        status "Only $(($(free_space_bytes) / 1024 / 1024 / 1024)) GiB is free on /. An update needs at least $UPDATE_MIN_FREE_GIB GiB."
        if update_unattended; then
            return 1
        fi
        if ! gum confirm --default=false "Update anyway?"; then
            status "Update cancelled. Free up some disk space and try again."
            return 0
        fi
    fi

    if ! ensure_update_tools; then
        status "Could not install pacman-contrib, which the update needs."
        return 1
    fi

    find_updates || return 1

    if [ "$total_count" -eq 0 ]; then
        status "No updates available. Your system is up to date."
        run_update_migrations || update_unattended_failed
        return
    fi

    show_updates
    choose_updates

    if [ "$selected_count" -eq 0 ]; then
        status "No updates selected."
        run_update_migrations || update_unattended_failed
        return
    fi

    check_reboot_patterns
    show_selection

    if ! update_confirm "Proceed with the selected updates?"; then
        status "Update cancelled."
        return 0
    fi

    if [ "$update_repo" = true ]; then
        prune_package_cache
        if ! update_system_packages; then
            status "The system packages could not be updated, so the migrations and AUR packages were skipped. Check the errors above and run the update again."
            return 1
        fi
    fi

    # The steps after the system packages go on when one of them fails. An unattended update
    # still ends with an error then, so whoever started it sees that something needs a look.
    local failed=false
    run_update_migrations || failed=true
    update_aur_packages || failed=true
    finish_update

    if [ "$failed" = true ]; then
        update_unattended_failed
    fi
}

# Interactively the problem was already shown, and the menu stays open.
update_unattended_failed() {
    ! update_unattended
}

disable_sleep
update_exit_code=0
run_update || update_exit_code=$?
enable_sleep
return "$update_exit_code"
