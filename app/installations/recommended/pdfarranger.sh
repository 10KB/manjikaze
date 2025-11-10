install() {
    install_package "pdfarranger" aur
    install_package "img2pdf" repo # Dependency for image-to-pdf conversion
    install_package "ghostscript" repo # Dependency for shrinkpdf
    install_package "shrinkpdf" aur # AUR helper script for reducing PDF size
}

uninstall() {
    uninstall_package "pdfarranger" aur
    uninstall_package "img2pdf" repo
    uninstall_package "ghostscript" repo
    uninstall_package "shrinkpdf" aur
}
