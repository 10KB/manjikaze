#!/bin/bash
set -e

# The weekly update check ran sudo without a terminal, so it never refreshed the package databases.
# It now uses checkupdates from pacman-contrib, which needs no root.

if ! systemctl --user is-enabled manjikaze-update-check.timer &>/dev/null; then
    status "Weekly update checks are not enabled, skipping."
    return 0
fi

if command -v checkupdates &>/dev/null; then
    status "checkupdates is already installed, skipping."
    return 0
fi

install_package "pacman-contrib" repo
