status "Installing Alacritty terminal..."
sudo pacman -S alacritty --noconfirm --noprogressbar --quiet

if [ ! -d ~/.config/alacritty ]; then
    mkdir -p ~/.config/alacritty
    cp ./configs/alacritty.toml ~/.config/alacritty/alacritty.toml
fi