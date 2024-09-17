sudo pacman -S yubikey-full-disk-encryption --noconfirm

# Ask the user if they want to set up a new YubiKey
read -p "Do you want to set up a new YubiKey? (y/n): " setup_new_yubikey

if [[ $setup_new_yubikey =~ ^[Yy]$ ]]; then
    echo "Configuring YubiKey for HMAC-SHA1 Challenge-Response mode..."
    echo "y" | ykpersonalize -2 -ochal-resp -ochal-hmac -ohmac-lt64 -oserial-api-visible -ochal-btn-trig > yk_output.tmp 2>&1
    secret_key=$(grep "key:" yk_output.tmp | awk '{print $2}')
    rm yk_output.tmp
    if [ -n "$secret_key" ]; then
        echo "Secret key: $secret_key" > yubikey_secret.txt
        echo "Secret key has been saved to yubikey_secret.txt. Store this file securely."
    else
        echo "Failed to retrieve the secret key. Please try again."
        exit 1
    fi
else
    echo "YubiKey is already configured for HMAC-SHA1 Challenge-Response mode."
fi

# Add YubiKey to LUKS encrypted volume
# Dynamically determine the encrypted root device
encrypted_device=$(findmnt -no SOURCE / | sed 's/\/dev\/mapper\///')
encrypted_device="$(lsblk -npo NAME,PKNAME | grep "$encrypted_device" | awk '{print $2}')"

# Edit /etc/ykfde.conf
sed -i 's/#YKFDE_CHALLENGE_PASSWORD_NEEDED="1"/YKFDE_CHALLENGE_PASSWORD_NEEDED="1"/' /etc/ykfde.conf
sed -i 's/#YKFDE_CHALLENGE_SLOT="2"/YKFDE_CHALLENGE_SLOT="2"/' /etc/ykfde.conf

# Set YKFDE_CHALLENGE
read -s -p "Enter your password to use as the YubiKey challenge: " user_password
echo
CHALLENGE=$(echo -n "$user_password" | sha256sum | awk '{print $1}')
sed -i "s/#YKFDE_CHALLENGE=\"\"/YKFDE_CHALLENGE=\"$CHALLENGE\"/" /etc/ykfde.conf

# Set YKFDE_DISK_UUID and YKFDE_LUKS_NAME
sed -i "s/#YKFDE_DISK_UUID=\"\"/YKFDE_DISK_UUID=\"$encrypted_device\"/" /etc/ykfde.conf
sed -i 's/#YKFDE_LUKS_NAME=""/YKFDE_LUKS_NAME="cryptlvm"/' /etc/ykfde.conf

# Enroll YubiKey for the determined encrypted device
sudo ykfde-enroll -d "$encrypted_device"

# # Enroll YubiKey for the determined encrypted device
# sudo ykfde-enroll -d "$encrypted_device"

# # Configure PAM for YubiKey authentication
# sudo sed -i '1i auth required pam_u2f.so' /etc/pam.d/system-auth
# sudo sed -i '1i auth required pam_u2f.so' /etc/pam.d/sudo

# # Configure auto-lock on YubiKey removal
# cat << EOF | sudo tee /etc/udev/rules.d/85-yubikey.rules
# ACTION=="remove", SUBSYSTEM=="usb", ENV{ID_VENDOR}=="Yubico", RUN+="/usr/bin/loginctl lock-sessions"
# EOF

# # Regenerate initramfs
# sudo mkinitcpio -P

# echo "YubiKey full disk encryption setup complete. Please reboot to test."
# echo "Remember to keep your YubiKey inserted during boot."
