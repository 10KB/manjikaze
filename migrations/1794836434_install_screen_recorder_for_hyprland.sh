#!/bin/bash
set -e

# Print in Hyprland now also records the screen, with gpu-screen-recorder.

if ! is_installed hyprland; then
    status "Hyprland is not installed, skipping."
    return 0
fi

install_package "gpu-screen-recorder" repo
install_package "ffmpeg" repo
