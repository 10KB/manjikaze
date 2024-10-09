yubikey_bitwarden() {
    echo "Configuration of a Yubikey for Bitwarden requires manual setup in the browser."
    echo "1. Open the Bitwarden vault at https://vault.bitwarden.com/."
    echo "2. Navigate to 'Settings' > 'Security' > 'Two-step login'."
    echo "3. Click 'Manage' on the Passkey FIDO2 item."
    echo "4. Enter a name to identify your Yubikey."
    echo "5. Make sure your Yubikey is inserted and click the Read key button."
    echo "6. Click 'Save' to complete the setup."

    if gum confirm "Do you want to open the Bitwarden vault in your default browser?"; then
        xdg-open "https://vault.bitwarden.com/"
    fi
}