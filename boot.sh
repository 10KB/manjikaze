#!/bin/bash

set -e

function status() {
    time=$(date +%T)
    echo -e "\n\033[1;32m$time\033[0m - \033[0;32m$1\033[0m\n"
}

status "Requesting sudo permissions..."
sudo -v -p "We need sudo permissions for the installation process. Please enter your password: "

# Keep sudo alive
while true; do sudo -n true; sleep 3600; kill -0 "$$" || exit; done 2>/dev/null &

status "Starting with updating installed packages..."
sudo pacman -Syu --noconfirm --noprogressbar --quiet

status "Pulling latest version of setup..."
sudo pacman -Sy git --noconfirm --noprogressbar --quiet

status "Installation starting..."
source ./install.sh
