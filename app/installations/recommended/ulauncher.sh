install() {
    install_package "ulauncher" aur

    mkdir -p ~/.config/autostart/
    if [ ! -f ~/.config/autostart/ulauncher.desktop ]; then
        cp "$MANJIKAZE_DIR/configs/ulauncher.desktop" ~/.config/autostart/
    fi

    mkdir -p ~/.config/ulauncher/
    if [ ! -f ~/.config/ulauncher/settings.json ]; then
        cp "$MANJIKAZE_DIR/configs/ulauncher.json" ~/.config/ulauncher/settings.json
    fi
}

uninstall() {
    uninstall_package "ulauncher" aur
}
