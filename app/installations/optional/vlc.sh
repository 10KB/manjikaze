# The vlc package plays almost nothing on its own: the codecs, ffmpeg among them, come in plugin packages.
install() {
    install_package "vlc" repo
    install_package "vlc-plugins-all" repo
}

uninstall() {
    uninstall_package "vlc-plugins-all" repo
    uninstall_package "vlc" repo
}
