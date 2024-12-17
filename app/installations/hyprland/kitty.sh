install_if_not_present "kitty" "pacman -S kitty --noconfirm --noprogressbar --quiet"

if [ ! -d "$HOME/.config/kitty" ]; then
    mkdir -p "$HOME/.config/kitty"
    cp /usr/share/doc/kitty/kitty.conf "$HOME/.config/kitty/kitty.conf" 2>/dev/null || true
fi