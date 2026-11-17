replace_yubikey=$(gum confirm "Do you want to replace a faulty YubiKey with a new one? This will overwrite the 2nd slot on your new YubiKey." --affirmative "Yes" --negative "No" --default=false && echo "true" || echo "false")

if [[ $replace_yubikey == "true" ]]; then
    echo "This process will replace a faulty YubiKey with a new one."
    echo "Please ensure you have the 20-byte secret key from the original YubiKey setup."
    echo "Do NOT insert the new YubiKey yet."

    suspend_rule_present=false
    if [ -f /etc/udev/rules.d/90-yubikey-actions.rules ]; then
        suspend_rule_present=true
        sudo mv /etc/udev/rules.d/90-yubikey-actions.rules /etc/udev/rules.d/90-yubikey-actions.rules.bak
        sudo udevadm control --reload-rules
        sudo udevadm trigger
    fi

    echo "Please authenticate with your password to proceed."
    sudo -v

    if [ $? -ne 0 ]; then
        echo "Authentication failed. Aborting YubiKey replacement."
        return 1
    fi

    echo "Authentication successful."
    echo "Please insert your new YubiKey now."
    gum confirm "Have you inserted the new YubiKey?" || return 1

    secret_key=$(gum input --prompt "Enter the 20-byte secret key from the original YubiKey setup: ")

    if ! [[ $secret_key =~ ^[0-9a-fA-F]{40}$ ]]; then
        echo "Error: Invalid secret key format. It should be 40 hexadecimal characters (20 bytes)."
        return 1
    fi

    if ! command -v ykpersonalize &> /dev/null; then
        echo "ykpersonalize is not installed. Installing yubikey-personalization..."
        sudo pacman -S yubikey-personalization --noconfirm
    fi

    echo "Configuring new YubiKey..."
    if ! ykpersonalize -a$secret_key -v -2 -ochal-resp -ochal-hmac -ohmac-lt64 -ochal-btn-trig -oserial-api-visible; then
        echo "Error: Failed to configure the new YubiKey."
        return 1
    fi

    if [ "$suspend_rule_present" = true ]; then
        sudo mv /etc/udev/rules.d/90-yubikey-actions.rules.bak /etc/udev/rules.d/90-yubikey-actions.rules
        sudo udevadm control --reload-rules
        sudo udevadm trigger
    fi

    echo "New YubiKey configured successfully."
    echo "Your new YubiKey is now set up and should work like the original one."
    echo "Please test it by rebooting your system and using the new YubiKey to unlock the disk."

    if grep -qs "pam_u2f.so" /etc/pam.d/system-auth; then
        source "$MANJIKAZE_DIR/lib/yubikey-pam.sh"
        if gum confirm "Register the new YubiKey for unlock, sudo and polkit? Keys registered before stop working there."; then
            yubikey_pam_configure replace || status "Run Security → Configure Yubikey as MFA for system to try again."
        fi
    fi
fi