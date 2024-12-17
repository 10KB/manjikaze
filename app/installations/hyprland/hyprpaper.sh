install_if_not_present "hyprpaper" "pacman -S hyprpaper --noconfirm --noprogressbar --quiet"

if [ ! -d "$HOME/.config/hypr" ]; then
    mkdir -p "$HOME/.config/hypr"
    cp /usr/share/hyprpaper/hyprpaper.conf "$HOME/.config/hypr/hyprpaper.conf" 2>/dev/null || true
fi