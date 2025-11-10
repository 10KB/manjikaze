install() {
    install_package "spotify" aur
    install_package "xdg-desktop-portal-gtk" repo
}

uninstall() {
    uninstall_package "spotify" aur
    uninstall_package "xdg-desktop-portal-gtk" repo
}
