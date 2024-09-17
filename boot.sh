#!/bin/bash

set -e

function status() {
    time=$(date +%T)
    echo -e "\n\033[1;32m$time\033[0m - \033[0;32m$1\033[0m\n"
}

status "Starting with updating installed packages..."

sudo pacman -Syu --noconfirm

status "Pulling latest version of setup..."
sudo pacman -Sy git --noconfirm

status "Installation starting..."
source ./install.sh
