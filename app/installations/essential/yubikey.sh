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

sudo systemctl enable pcscd.service
sudo systemctl start pcscd.service
