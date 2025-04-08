install_package "flameshot" repo

if [ ! -d ~/.config/flameshot ]; then
    mkdir -p ~/.config/flameshot
    cp "$MANJIKAZE_DIR/configs/flameshot.ini" ~/.config/flameshot/flameshot.ini
fi
