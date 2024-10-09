install_if_not_present "alacritty" "sudo pacman -S alacritty --noconfirm --noprogressbar --quiet"

if [ ! -d ~/.config/alacritty ]; then
    mkdir -p ~/.config/alacritty
    cp ./configs/alacritty.toml ~/.config/alacritty/alacritty.toml
fi