#!/bin/bash
set -e

if ! command -v mise &> /dev/null; then
    status "Migrating runtimes to mise management..."

    source "$MANJIKAZE_DIR/app/installations/essential/mise.sh"
    install

    PACKAGES_TO_REMOVE=("nodejs-lts-iron" "npm" "python-pip" "python-pipx")
    REMOVED_PACKAGES=()
    SKIPPED_PACKAGES=()

    status "Checking for redundant system packages..."
    for package in "${PACKAGES_TO_REMOVE[@]}"; do
        if pacman -Q "$package" &>/dev/null; then
            status "Found redundant package: $package (now managed by mise)"

            # Check for dependencies before attempting removal
            if pacman -Rp "$package" &>/dev/null; then
                # No dependency issues, safe to remove
                if gum confirm "Remove $package from system? (It's now managed by mise)"; then
                    status "Removing $package..."
                    sudo pacman -R --noconfirm --noprogressbar "$package" && {
                        REMOVED_PACKAGES+=("$package")
                    } || {
                        status "Warning: Failed to remove $package, continuing anyway"
                        SKIPPED_PACKAGES+=("$package")
                    }
                else
                    status "Keeping $package installed system-wide"
                    SKIPPED_PACKAGES+=("$package: user chose to keep")
                fi
            else
                status "Warning: Cannot remove $package due to dependencies"
                SKIPPED_PACKAGES+=("$package: dependency issues")
            fi
        fi
    done

    if [ ${#REMOVED_PACKAGES[@]} -eq 0 ]; then
        status "No system packages were removed."
    else
        status "Successfully removed: ${REMOVED_PACKAGES[*]}"
    fi

    if [ ${#SKIPPED_PACKAGES[@]} -gt 0 ]; then
        status "The following packages were kept due to dependencies or user choice:"
        for pkg in "${SKIPPED_PACKAGES[@]}"; do
            status "  - $pkg"
        done
        status "This is OK - mise will still manage runtimes in your user environment"
        status "System packages will only be used by applications that depend on them"
    fi

    status "Mise migration completed! You can now manage runtimes with 'mise' command."
    status "Type 'mise help' for more information or see the documentation."
fi

