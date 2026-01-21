install() {
    install_package "visual-studio-code-bin" aur

    if [ ! -d ~/.config/Code/User ]; then
        mkdir -p ~/.config/Code/User
        cp "$MANJIKAZE_DIR/configs/code.json" ~/.config/Code/User/settings.json
    fi
}

uninstall() {
    uninstall_package "visual-studio-code-bin" aur
}
