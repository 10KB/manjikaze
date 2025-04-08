install_package "code" repo

if [ ! -d ~/.config/Code\ -\ OSS/User ]; then
    mkdir -p ~/.config/Code\ -\ OSS/User
    cp "$MANJIKAZE_DIR/configs/code.json" ~/.config/Code\ -\ OSS/User/settings.json
fi
