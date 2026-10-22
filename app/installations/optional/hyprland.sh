HYPRLAND_REPO_PACKAGES=(
    # Compositor, session management and portals (screen sharing, file pickers)
    hyprland uwsm libnewt xdg-desktop-portal-hyprland xdg-desktop-portal-gtk hyprpolkitagent
    # Lock screen, idle handling, wallpaper, color picker
    hyprlock hypridle hyprpaper hyprpicker
    # Notifications/quick settings and volume/brightness on-screen display
    swaync swayosd libnotify
    # Settings UIs: displays, GTK appearance, network/VPN, bluetooth, audio
    nwg-displays nwg-look network-manager-applet blueman bluez-utils pavucontrol
    # Screenshots, clipboard and media keys
    grim slurp satty wl-clipboard playerctl brightnessctl xdg-user-dirs
    # Used by the launcher providers and manjikaze-hypr-* scripts
    libqalculate inotify-tools socat lua jq
    qt5-wayland qt6-wayland
)

HYPRLAND_AUR_PACKAGES=(
    walker-bin
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
)

# Waybar 0.15 still sends hyprlang dispatch commands, so clicking a workspace does nothing
# under Hyprland's Lua config. Build from git until the repositories ship 0.16.
hyprland_waybar_package() {
    local version
    version=$(pacman -Si waybar 2>/dev/null | awk -F': ' '/^Version/ { print $2; exit }')

    if [[ -n $version ]] && [[ $(vercmp "$version" 0.16) -ge 0 ]]; then
        echo "waybar repo"
    else
        echo "waybar-git aur"
    fi
}

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

install() {
    local package waybar_package waybar_type

    for package in "${HYPRLAND_REPO_PACKAGES[@]}"; do
        install_package "$package" repo
    done

    read -r waybar_package waybar_type <<<"$(hyprland_waybar_package)"
    if ! is_installed waybar && ! is_installed waybar-git; then
        install_package "$waybar_package" "$waybar_type"
    elif is_installed waybar && [[ $waybar_package == "waybar-git" ]]; then
        status "Keeping the installed Waybar 0.15: clicking workspaces in the bar won't work until 0.16."
        status "Replace it with 'yay -S waybar-git' to get that now."
    fi

    for package in "${HYPRLAND_AUR_PACKAGES[@]}"; do
        install_package "$package" aur
    done

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
    local package

    rm -f ~/.config/systemd/user/manjikaze-hyprland.target ~/.config/systemd/user/manjikaze-*.service
    systemctl --user daemon-reload

    rm -f ~/.config/autostart/nm-applet.desktop ~/.config/autostart/blueman.desktop

    if [[ $(hyprland_default_session) == hyprland* ]]; then
        status "Switching the default session back to GNOME..."
        hyprland_set_default_session gnome
    fi

    for package in "${HYPRLAND_AUR_PACKAGES[@]}"; do
        uninstall_package "$package" aur
    done
    uninstall_package "waybar-git" aur
    uninstall_package "waybar" repo

    # Shared tools (grim, jq, lua, pavucontrol, ...) stay installed; other apps may use them.
    # Blueman goes: without the override above its applet would autostart in GNOME.
    for package in hyprland uwsm xdg-desktop-portal-hyprland hyprpolkitagent hyprlock hypridle hyprpaper \
        hyprpicker swaync swayosd nwg-displays satty blueman; do
        uninstall_package "$package" repo
    done

    status "Hyprland removed. Your configuration in ~/.config/hypr was left in place."
}
