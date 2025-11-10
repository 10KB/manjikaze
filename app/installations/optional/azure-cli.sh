install() {
    install_package "azure-cli" repo
    install_package "azure-kubelogin" repo
}

uninstall() {
    uninstall_package "azure-cli" repo
    uninstall_package "azure-kubelogin" repo
}
