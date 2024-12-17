install_if_not_present "hyprland" "pacman -S hyprland --noconfirm --noprogressbar --quiet"

if [ ! -d "$HOME/.config/hypr" ]; then
    mkdir -p "$HOME/.config/hypr"
    cp /usr/share/hyprland/hyprland.conf "$HOME/.config/hypr/hyprland.conf" 2>/dev/null || true
fi