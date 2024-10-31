install_if_not_present "yubikey-manager" "sudo pacman -S yubikey-manager --noconfirm"
install_if_not_present "yubico-pam" "sudo pacman -S yubico-pam --noconfirm"
install_if_not_present "yubikey-full-disk-encryption" "sudo pacman -S yubikey-full-disk-encryption --noconfirm"
install_if_not_present "gnupg" "sudo pacman -S gnupg --noconfirm"
install_if_not_present "ccid" "sudo pacman -S ccid --noconfirm"
install_if_not_present "pcsclite" "sudo pacman -S pcsclite --noconfirm"
install_if_not_present "hopenpgp-tools" "sudo pacman -S hopenpgp-tools --noconfirm"
install_if_not_present "yubikey-personalization" "sudo pacman -S yubikey-personalization --noconfirm"
install_if_not_present "expect" "sudo pacman -S expect --noconfirm"
sudo systemctl enable pcscd.service
sudo systemctl start pcscd.service