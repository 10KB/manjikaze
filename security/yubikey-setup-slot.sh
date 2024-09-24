setup_yubikey_slot() {
    setup_new_yubikey=$(gum confirm "Do you want to set up a new YubiKey? This will overwrite any existing 2nd slot on your YubiKey." --affirmative "Yes" --negative "No" && echo "true" || echo "false")

    if [[ $setup_new_yubikey =~ ^[Yy]$ ]]; then
        if ! pacman -Qi yubikey-manager &> /dev/null; then
            sudo pacman -S yubikey-manager --noconfirm
        fi

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
}