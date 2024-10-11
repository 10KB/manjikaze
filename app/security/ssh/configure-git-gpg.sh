configure_git_gpg() {
    local setup_gpg=$(gum confirm "Do you want to configure Git to use GPG for signing commits?" --affirmative "Yes" --negative "No" --default=false && echo "true" || echo "false")

    if [[ $setup_gpg == "true" ]]; then
        if ! command -v gpg &> /dev/null; then
            status "GPG is not installed. Please install it first."
            return 1
        fi

        local key_id=$(gpg --list-secret-keys --keyid-format LONG | grep sec | cut -d'/' -f2 | cut -d' ' -f1)

        if [ -z "$key_id" ]; then
            status "No GPG key found. Please generate a GPG key first."
            return 1
        fi

        git config --global user.signingkey $key_id
        git config --global commit.gpgsign true

        echo "Git configured to use GPG key: $key_id"
        echo "To add this key to your GitHub account, run:"
        echo "gpg --armor --export $key_id"
        echo "Then copy the output and paste it into your GitHub settings."
    fi
}
