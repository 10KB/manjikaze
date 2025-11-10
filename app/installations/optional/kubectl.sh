install() {
    install_package "kubectl" aur
    install_package "helm" aur
    install_package "eksctl" aur
    install_package "lens-bin" aur
}

uninstall() {
    uninstall_package "kubectl" aur
    uninstall_package "helm" aur
    uninstall_package "eksctl" aur
    uninstall_package "lens-bin" aur
}
