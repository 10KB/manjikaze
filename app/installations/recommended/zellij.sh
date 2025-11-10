install() {
    install_package "zellij" repo

    mkdir -p ~/.config/zellij
    if [ ! -f ~/.config/zellij/config.kdl ] || ! cmp -s "$MANJIKAZE_DIR/configs/zellij.kdl" ~/.config/zellij/config.kdl; then
        cp "$MANJIKAZE_DIR/configs/zellij.kdl" ~/.config/zellij/config.kdl
    fi
}

uninstall() {
    uninstall_package "zellij" repo
}
