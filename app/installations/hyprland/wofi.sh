install_if_not_present "wofi" "pacman -S wofi --noconfirm --noprogressbar --quiet"

if [ ! -d "$HOME/.config/wofi" ]; then
    mkdir -p "$HOME/.config/wofi"
    cp /usr/share/wofi/config "$HOME/.config/wofi/config" 2>/dev/null || true
fi