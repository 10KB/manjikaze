install() {
    install_package "opensnitch" repo

    sudo systemctl enable --now opensnitchd

    mkdir -p ~/.config/autostart/
    cp /usr/share/applications/opensnitch_ui.desktop ~/.config/autostart/
}

uninstall() {
    sudo systemctl disable --now opensnitchd

    rm -f ~/.config/autostart/opensnitch_ui.desktop

    uninstall_package "opensnitch" repo
}
