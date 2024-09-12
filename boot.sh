#!/bin/bash

set -e

echo -e "\n## Starting with updating installed packages...\n"

sudo pacman -Syu --noconfirm

echo -e "\n## Pulling latest version of setup...\n"
sudo pacman -Sy git --noconfirm

echo -e "\n## Installation starting...\n"
source ./install.sh
