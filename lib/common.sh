#!/bin/bash

status() {
    time=$(date +%T)
    echo -e "\n\033[1;32m$time\033[0m - \033[0;32m$1\033[0m\n"
}


# Version management
get_version() {
    git -C "$MANJIKAZE_DIR" describe --tags 2>/dev/null || echo "dev"
}

is_installed() {
    pacman -Qi "$1" &> /dev/null
}

install_if_not_present() {
    local package=$1
    local install_command=$2

    if ! is_installed "$package"; then
        status "Installing $package..."
        eval "$install_command"
    else
        status "$package is already installed. Skipping."
    fi
}

sudo -v -p "We need sudo permissions for the installation process. Please enter your password: "

# Keep sudo alive
while true; do sudo -n true; sleep 3600; kill -0 "$$" || exit; done 2>/dev/null &
