install() {
    install_package "displaylink" aur

    local kernel_short=$(kernel_version_short)
    install_package "linux${kernel_short}-headers" repo
}

uninstall() {
    uninstall_package "displaylink" aur

    local kernel_short=$(kernel_version_short)
    uninstall_package "linux${kernel_short}-headers" repo
}

kernel_version_short() {
    local kernel_version=$(uname -r) # e.g. 6.12.77-1-MANJARO
    echo "$kernel_version" | grep -oP '^\d+\.\d+' | tr -d '.' # e.g. 612
}
