install_package "alacritty" repo

if [ ! -d ~/.config/alacritty ]; then
    mkdir -p ~/.config/alacritty
    cp ./configs/alacritty.toml ~/.config/alacritty/alacritty.toml
fi