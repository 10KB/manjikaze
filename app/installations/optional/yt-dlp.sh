install() {
    install_package "yt-dlp" repo
    install_package "ffmpeg" repo
    install_package "parabolic-gtk" aur
}

uninstall() {
    uninstall_package "yt-dlp" repo
    uninstall_package "ffmpeg" repo
    uninstall_package "parabolic-gtk" aur
}
