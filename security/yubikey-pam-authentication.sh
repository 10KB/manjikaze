configure_pam_auth() {
    if ! pacman -Qi yubico-pam &> /dev/null; then
        echo "Installing yubico-pam..."
        sudo pacman -S yubico-pam --noconfirm
    else
        echo "yubico-pam is already installed."
    fi

    echo "Setting up YubiKey challenge-response..."
    mkdir -p ~/.yubico
    ykpamcfg -2 -v

    echo "Moving challenge file to /var/yubico..."
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
        
        if ! sudo grep -q "$auth_line" "$pam_file"; then
            echo "Adding YubiKey authentication to $pam_file..."
            sudo sed -i "1i$auth_line" "$pam_file"
        else
            echo "YubiKey authentication already configured in $pam_file."
        fi
    }

    add_yubikey_auth /etc/pam.d/sudo
    add_yubikey_auth /etc/pam.d/system-auth
    add_yubikey_auth /etc/pam.d/login
    add_yubikey_auth /etc/pam.d/polkit-1

    echo "PAM authentication with YubiKey has been configured for system-wide use."
    echo "This includes sudo, login, and GUI password prompts."
    echo "Please test it by running 'sudo ls' in a new terminal."
    echo "If it doesn't work, you can still use your password."
}