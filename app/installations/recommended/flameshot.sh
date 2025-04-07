install_package "flameshot" repo

if [ ! -d ~/.config/flameshot ]; then
    mkdir -p ~/.config/flameshot
    cp ./configs/flameshot.ini ~/.config/flameshot/flameshot.ini
fi
