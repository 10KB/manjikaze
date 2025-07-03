setup_yubikey_pam=$(gum confirm "Do you want to set up YubiKey PAM authentication?" --affirmative "Yes" --negative "No" --default=false && echo "true" || echo "false")

if [[ $setup_yubikey_pam == "true" ]]; then
    status "Setting up YubiKey challenge-response..."
    mkdir -p ~/.yubico
    ykpamcfg -2 -v

    status "Moving challenge file to /var/yubico..."
    sudo mkdir -p /var/yubico
    sudo chown root:root /var/yubico
    sudo chmod 700 /var/yubico
    challenge_file=$(ls ~/.yubico/challenge-* | head -n 1)
    user_name=$(whoami)
    challenge_number=$(basename "$challenge_file" | cut -d'-' -f2)
    sudo mv -f "$challenge_file" "/var/yubico/${user_name}-${challenge_number}"
    sudo chown root:root /var/yubico/${user_name}-${challenge_number}
    sudo chmod 600 /var/yubico/${user_name}-${challenge_number}

    add_yubikey_auth() {
        local pam_file="$1"
        local auth_line="auth sufficient pam_yubico.so mode=challenge-response chalresp_path=/var/yubico"

        if [ ! -f "$pam_file" ]; then
            status "PAM file $pam_file does not exist. Skipping."
            return
        fi

        if ! sudo grep -q "$auth_line" "$pam_file"; then
            status "Adding YubiKey authentication to $pam_file..."
            sudo sed -i "1i$auth_line" "$pam_file"
        else
            status "YubiKey authentication already configured in $pam_file."
        fi
    }

    add_yubikey_auth /etc/pam.d/sudo
    add_yubikey_auth /etc/pam.d/system-auth
    add_yubikey_auth /etc/pam.d/login
    add_yubikey_auth /etc/pam.d/polkit-1
    add_yubikey_auth /etc/pam.d/gnome-keyring

    if [ -f "/etc/pam.d/login" ] && ! sudo grep -q "pam_gnome_keyring.so" /etc/pam.d/login; then
        sudo sed -i '/^session/a\session    optional     pam_gnome_keyring.so auto_start' /etc/pam.d/login
        sudo sed -i '/^auth/a\auth       optional     pam_gnome_keyring.so' /etc/pam.d/login
    fi

    local prompt_line="auth optional pam_echo.so Please touch your yubikey."

    if ! sudo grep -q "$prompt_line" "/etc/pam.d/sudo"; then
        status "Adding prompt to /etc/pam.d/sudo..."
        sudo sed -i "1i$prompt_line" "/etc/pam.d/sudo"
    fi

    if sudo test -f "/etc/sudoers.d/99-yubikey-prompt" ; then
        status "Prompt already configured in /etc/sudoers.d/99-yubikey-prompt."
    else
        tmp=$(mktemp)
        cat >"$tmp" <<'EOF'
# added by manjikaze-setup – YubiKey touch prompt
Defaults !pam_silent
EOF

        if ! sudo visudo -cf "$tmp"; then
            echo "ERROR: sudoers syntax check failed"
            rm -f "$tmp"
            return 1
        fi

        sudo install -o root -g root -m 0440 "$tmp" /etc/sudoers.d/99-yubikey-prompt
        rm -f "$tmp"
    else
        status "Prompt already configured in /etc/pam.d/sudo."
    fi

    echo "PAM authentication with YubiKey has been configured for system-wide use."
    echo "This includes sudo, login, and GUI password prompts."
    echo "Please test it by running 'sudo ls' in a new terminal."
    echo "If it doesn't work, you can still use your password."
fi