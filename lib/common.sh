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

install_package() {
    local package=$1
    local type=${2:-repo} # Default to repo
    local cmd

    if is_installed "$package"; then
        status "Package '$package' is already installed. Skipping."
        return 0
    fi

    if [[ "$type" == "aur" ]]; then
        status "Installing AUR package $package..."
        cmd="yay -S $package --noconfirm --noprogressbar --quiet"
    else
        status "Installing repository package $package..."
        cmd="sudo pacman -S $package --noconfirm --noprogressbar --quiet"
    fi

    set +e
    output=$(eval $cmd 2>&1)
    if [[ $? -ne 0 ]]; then
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

