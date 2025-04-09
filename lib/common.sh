#!/bin/bash

status() {
    time=$(date +%T)
    echo -e "\033[1;32m$time\033[0m - \033[0;32m$1\033[0m"
}

get_version() {
    git -C "$MANJIKAZE_DIR" describe --tags 2>/dev/null || echo "dev"
}

is_installed() {
    pacman -Qi "$1" &> /dev/null
}

disable_sleep() {
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
        status "Disabling screen lock and sleep during installation..."
        gsettings set org.gnome.desktop.screensaver lock-enabled false
        gsettings set org.gnome.desktop.session idle-delay 0
    fi
}

enable_sleep() {
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
        status "Re-enabling screen lock and sleep..."
        gsettings set org.gnome.desktop.screensaver lock-enabled true
        gsettings set org.gnome.desktop.session idle-delay 300
    fi
}

install_package() {
    local package=$1
    local type=${2:-repo} # Default to repo

    if is_installed "$package"; then
        status "Package '$package' is already installed. Skipping."
        return 0
    fi

    set +e
    local output
    if [[ "$type" == "aur" ]]; then
        status "Installing AUR package $package..."
        output=$(yay -S "$package" --noconfirm --noprogressbar --quiet 2>&1)
    else
        status "Installing repository package $package..."
        output=$(sudo pacman -S "$package" --noconfirm --noprogressbar --quiet 2>&1)
    fi
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        status "Failed to install $package"

        if ! gum confirm "Continue with installation of other packages?"; then
            return 2 # Special code to indicate user-requested abort
        fi

        status "Continuing installation process..."
        return 1 # Indicate failure but script continues
    else
        status "Package '$package' installed successfully."
    fi
    set -e
}

