HYPRLAND_REPO_PACKAGES=(
    # Compositor, session management, portals (screen sharing, file pickers), Qt on Wayland
    # and notify-send for the manjikaze-hypr-* scripts
    hyprland uwsm libnewt xdg-desktop-portal-hyprland xdg-desktop-portal-gtk hyprpolkitagent
    qt5-wayland qt6-wayland libnotify
    # Displays settings and the monitor profile daemon
    nwg-displays inotify-tools socat lua jq
    # Launcher providers: calculator and clipboard
    libqalculate wl-clipboard
)

HYPRLAND_AUR_PACKAGES=(
    # Elephant first: walker-bin depends on "elephant", and with elephant-bin missing yay
    # builds the source package instead, which conflicts with the -bin providers.
    elephant-bin
    elephant-providerlist-bin
    elephant-desktopapplications-bin
    elephant-calc-bin
    elephant-clipboard-bin
    elephant-files-bin
    elephant-symbols-bin
    elephant-websearch-bin
    elephant-runner-bin
    elephant-bluetooth-bin
    elephant-wireplumber-bin
    walker-bin
)

# Removed again by uninstall. The other packages above stay installed, because other apps
# may use them.
HYPRLAND_OWN_PACKAGES=(
    hyprland uwsm xdg-desktop-portal-hyprland hyprpolkitagent
    nwg-displays
)

# Session GDM starts for this user (also with automatic login): hyprland-uwsm or gnome.
hyprland_set_default_session() {
    local session="$1" user_path
    local user_file="/var/lib/AccountsService/users/$USER"
    user_path="/org/freedesktop/Accounts/User$(id -u)"

    if busctl call org.freedesktop.Accounts "$user_path" org.freedesktop.Accounts.User SetSession s "$session" >/dev/null 2>&1; then
        return 0
    fi

    # Older AccountsService without SetSession: edit its user file directly.
    if sudo test -f "$user_file"; then
        if sudo grep -q '^Session=' "$user_file"; then
            sudo sed -i "s/^Session=.*/Session=$session/" "$user_file"
        else
            sudo sed -i "/^\[User\]/a Session=$session" "$user_file"
        fi
    else
        printf '[User]\nSession=%s\n' "$session" | sudo tee "$user_file" >/dev/null
    fi
}

hyprland_default_session() {
    busctl get-property org.freedesktop.Accounts "/org/freedesktop/Accounts/User$(id -u)" \
        org.freedesktop.Accounts.User Session 2>/dev/null | awk -F'"' '{ print $2 }'
}

# A package database older than the mirror points at files that no longer exist (404).
hyprland_package_database_current() {
    local url
    url=$(pacman -Sp hyprland 2>/dev/null | tail -1)
    [[ $url != http* ]] || [[ $(curl -s -o /dev/null -w '%{http_code}' -I "$url") != 404 ]]
}

# Installs the packages that are missing. Returns 1 when the user stops after a failed one.
hyprland_install_packages() {
    local package

    for package in "${HYPRLAND_REPO_PACKAGES[@]}"; do
        is_installed "$package" || install_package "$package" repo || [[ $? -ne 2 ]] || return 1
    done
    for package in "${HYPRLAND_AUR_PACKAGES[@]}"; do
        is_installed "$package" || install_package "$package" aur || [[ $? -ne 2 ]] || return 1
    done
}

install() {
    if ! hyprland_package_database_current; then
        status "The package database is out of date, so the Hyprland packages can't be downloaded."
        status "Update the system first (Setup > Update installed apps, or 'sudo pacman -Syu'), then run this again."
        return 0
    fi

    hyprland_install_packages || return 0

    if lspci | grep -qi 'nvidia'; then
        # Hardware video decoding in browsers on NVIDIA.
        install_package "libva-nvidia-driver" repo
    fi

    if ! is_installed hyprland || ! is_installed uwsm; then
        status "Hyprland or uwsm failed to install; not configuring the session. Run this again to retry."
        return 0
    fi

    source "$MANJIKAZE_DIR/app/configuration/configure-hyprland.sh"
}

uninstall() {
    local unit package index

    # Only the units configure-hyprland.sh deployed; other manjikaze-* units aren't Hyprland's.
    for unit in "$MANJIKAZE_DIR"/configs/systemd/user/*; do
        rm -f "$HOME/.config/systemd/user/$(basename "$unit")"
    done
    systemctl --user daemon-reload

    if [[ $(hyprland_default_session) == hyprland* ]]; then
        status "Switching the default session back to GNOME..."
        hyprland_set_default_session gnome
    fi

    # Reverse order: walker-bin and the providers depend on elephant-bin.
    for ((index = ${#HYPRLAND_AUR_PACKAGES[@]} - 1; index >= 0; index--)); do
        uninstall_package "${HYPRLAND_AUR_PACKAGES[$index]}" aur
    done

    for package in "${HYPRLAND_OWN_PACKAGES[@]}"; do
        uninstall_package "$package" repo
    done

    status "Hyprland removed. Your configuration in ~/.config/hypr was left in place."
}
