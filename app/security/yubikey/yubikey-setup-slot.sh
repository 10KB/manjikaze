setup_new_yubikey=$(gum confirm "Do you want to set up a new YubiKey? This will overwrite any existing 2nd slot on your YubiKey." --affirmative "Yes" --negative "No" --default=false && echo "true" || echo "false")

if [[ $setup_new_yubikey == "true" ]]; then
    mkdir -p "$MANJIKAZE_DIR/secrets"

    status "Configuring YubiKey for HMAC-SHA1 Challenge-Response mode..."
    echo "y" | ykpersonalize -2 -ochal-resp -ochal-hmac -ohmac-lt64 -oserial-api-visible -ochal-btn-trig > yk_output.tmp 2>&1
    secret_key=$(grep "key:" yk_output.tmp | awk '{print $2}')
    rm yk_output.tmp
    if [ -n "$secret_key" ]; then
        echo "Secret key: $secret_key" > "$MANJIKAZE_DIR/secrets/yubikey-fde-key"
        status "Secret key has been saved to $MANJIKAZE_DIR/secrets/yubikey-fde-key. Store this file securely."
    else
        status "Failed to retrieve the secret key. Please try again."
        exit 1
    fi
fi