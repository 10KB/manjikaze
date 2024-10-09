install_if_not_present "flameshot" "sudo pacman --sync flameshot --noconfirm --noprogressbar --quiet"

if [ ! -d ~/.config/flameshot ]; then
    mkdir -p ~/.config/flameshot
    cp ./configs/flameshot.ini ~/.config/flameshot/flameshot.ini
fi