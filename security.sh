#!/bin/bash

set -e

source ./security/audit-user-password.sh
source ./security/audit-luks-volume.sh
source ./security/yubikey-setup-slot.sh
source ./security/yubikey-full-disk-encryption.sh
source ./security/yubikey-pam-authentication.sh
source ./security/yubikey-suspend.sh
# Main menu
while true; do
    CHOICE=$(gum choose \
        "Audit user password strength" \
        "Audit full disk encryption" \
        "Setup YubiKey slot" \
        "Setup Yubikey for full disk encryption" \
        "Setup Yubikey for PAM authentication" \
        "Setup YubiKey suspend" \
        "Exit" \
        --header "Select a security task:")

    case $CHOICE in
        "Audit user password strength")
            check_user_password
            ;;
        "Audit full disk encryption")
            verify_luks_encryption
            ;;
        "Setup YubiKey slot")
            setup_yubikey_slot
            ;;
        "Setup Yubikey for full disk encryption")
            configure_full_disk_encryption
            ;;
        "Setup Yubikey for PAM authentication")
            configure_pam_auth
            ;;
        "Setup YubiKey suspend")
            setup_yubikey_suspend
            ;;
        "Exit")
            break
            ;;
    esac

    echo "Press Enter to continue..."
    read
done

echo "Security configuration complete."
