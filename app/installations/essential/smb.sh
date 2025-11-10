install() {
    install_package "smbclient" repo
    install_package "gvfs" repo
    install_package "gvfs-smb" repo
    install_package "cifs-utils" repo
    install_package "wsdd" aur
    install_package "nautilus-share" repo
    install_package "manjaro-settings-samba" repo
}

uninstall() {
    uninstall_package "smbclient" repo
    uninstall_package "gvfs" repo
    uninstall_package "gvfs-smb" repo
    uninstall_package "cifs-utils" repo
    uninstall_package "wsdd" aur
    uninstall_package "nautilus-share" repo
    uninstall_package "manjaro-settings-samba" repo
}
