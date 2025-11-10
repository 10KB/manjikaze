install() {
    install_package "postgresql-client" repo
    install_package "mysql-clients" aur
}

uninstall() {
    uninstall_package "postgresql-client" repo
    uninstall_package "mysql-clients" aur
}
