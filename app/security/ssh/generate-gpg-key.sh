function generate_gpg_key() {
    local setup_gpg=$(gum confirm "Do you want to generate a new GPG key?" --affirmative "Yes" --negative "No" --default=false && echo "true" || echo "false")

    if [[ $setup_gpg == "true" ]]; then
        if ! command -v gpg &> /dev/null; then
            status "GPG is not installed. Please install it first."
            return 1
        fi

        if gpg --list-secret-keys --keyid-format LONG | grep -q "sec"; then
            status "A GPG key already exists. Skipping key generation."
            return 0
        fi

        local use_yubikey=$(gum confirm "Do you want to use a YubiKey for GPG?" --affirmative "Yes" --negative "No" --default=false && echo "true" || echo "false")

        local name=$(gum input --prompt "Enter your name: ")
        local email=$(gum input --prompt "Enter your email: ")

        if [[ $use_yubikey == "true" ]]; then
            status "Generating GPG key on YubiKey..."
            gpg --card-edit --command-fd 0 <<EOF
admin
generate
y
$name
$email
O
q
EOF
        else
            status "Generating GPG key locally..."
            gpg --batch --generate-key <<EOF
%echo Generating GPG key
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: $name
Name-Email: $email
Expire-Date: 0
%no-protection
%commit
%echo Done
EOF
        fi

        status "GPG key generated successfully."
    fi
}