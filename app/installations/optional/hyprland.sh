#!/bin/bash

install_package "hyprland" "repo"
install_package "hyprpaper" "repo"
install_package "hypridle" "repo"
install_package "hyprlock" "repo"
install_package "hyprpolkitagent" "repo"
install_package "hyprpicker" "repo"
install_package "slurp" "repo"
install_package "waybar" "repo"
install_package "rofi-wayland" "repo"


if [ ! -d ~/.config/hypr ]; then
    rsync -a --ignore-existing configs/hypr/ ~/.config/hypr/
    rsync -a --ignore-existing assets/background.jpg ~/.config/hypr/background.jpg
fi

if [ ! -d ~/.config/rofi ]; then
    rsync -a --ignore-existing configs/rofi/ ~/.config/rofi/
fi

if [ ! -d ~/.config/waybar ]; then
    rsync -a --ignore-existing configs/waybar/ ~/.config/waybar/
fi