install_if_not_present "hyprlock" "yay -S hyprlock --noconfirm --noprogressbar --quiet"

if [ ! -d "$HOME/.config/hypr" ]; then
    mkdir -p "$HOME/.config/hypr"
    cp /usr/share/hyprlock/hyprlock.conf "$HOME/.config/hypr/hyprlock.conf" 2>/dev/null || true
fi