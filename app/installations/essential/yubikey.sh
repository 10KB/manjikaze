install() {
    install_package "yubikey-manager" repo
    install_package "yubico-pam" repo
    install_package "yubikey-full-disk-encryption" repo
    install_package "gnupg" repo
    install_package "ccid" repo
    install_package "pcsclite" repo
    install_package "hopenpgp-tools" repo
    install_package "yubikey-personalization" repo
    install_package "expect" repo
    install_package "pamtester" aur
    install_package "yubico-authenticator-bin" aur

    sudo systemctl enable pcscd.service
    sudo systemctl start pcscd.service
}

uninstall() {
    uninstall_package "yubikey-manager" repo
    uninstall_package "yubico-pam" repo
    uninstall_package "yubikey-full-disk-encryption" repo
    uninstall_package "gnupg" repo
    uninstall_package "ccid" repo
    uninstall_package "pcsclite" repo
    uninstall_package "hopenpgp-tools" repo
    uninstall_package "yubikey-personalization" repo
    uninstall_package "expect" repo
    uninstall_package "pamtester" aur
    uninstall_package "yubico-authenticator-bin" aur
}
