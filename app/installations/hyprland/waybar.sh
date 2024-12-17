install_if_not_present "waybar" "pacman -S waybar --noconfirm --noprogressbar --quiet"

if [ ! -d "$HOME/.config/waybar" ]; then
    mkdir -p "$HOME/.config/waybar"
    cp -r /etc/xdg/waybar/* "$HOME/.config/waybar/" 2>/dev/null || true
fi