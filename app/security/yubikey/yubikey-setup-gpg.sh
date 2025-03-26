source ./lib/bitwarden.sh

yubikey_setup_gpg() {
    local setup_gpg_ssh=$(gum confirm "Do you want to set up GPG and SSH with your YubiKey? This will reset any existing keys and configurations." --affirmative "Yes" --negative "No" --default=false && echo "true" || echo "false")

    if [[ $setup_gpg_ssh != "true" ]]; then
        return
    fi

    if ! ykman list | grep -q "YubiKey"; then
        status "Please insert your YubiKey and try again."
        return 1
    fi

    status "Stopping any running GPG agent services..."
    systemctl --user stop gpg-agent.socket gpg-agent.service gpg-agent-ssh.socket gpg-agent-extra.socket gpg-agent-browser.socket
    gpgconf --kill all

    sudo systemctl restart pcscd
    sleep 2

    status "Removing existing GPG configuration..."
    rm -rf ~/.gnupg
    mkdir -p ~/.gnupg
    chmod 700 ~/.gnupg

    status "Configuring GPG for YubiKey usage..."
    wget -q https://raw.githubusercontent.com/drduh/config/master/gpg.conf -O ~/.gnupg/gpg.conf
    chmod 600 ~/.gnupg/gpg.conf

    gpg_agent_configuration() {
        local key="$1"
        local value="$2"
        local line="$key${value:+ $value}"
        local gpg_agent_conf=~/.gnupg/gpg-agent.conf
        
        if grep -q "^$key" "$gpg_agent_conf"; then
            # If the key exists, replace the line
            sed -i "s|^$key.*|$line|" "$gpg_agent_conf"
        else
            # If the key doesn't exist, append the line
            echo "$line" >> "$gpg_agent_conf"
        fi
    }
    touch ~/.gnupg/gpg-agent.conf
    chmod 600 ~/.gnupg/gpg-agent.conf
    gpg_agent_configuration "enable-ssh-support"
    gpg_agent_configuration "default-cache-ttl" "3600" # Setting a long cache ttl to prevent frequent PIN prompts
    gpg_agent_configuration "max-cache-ttl" "7200"
    gpg_agent_configuration "pinentry-program" "/usr/bin/pinentry-curses" # Temporary pinentry program for unattended operations

    echo "disable-ccid" > ~/.gnupg/scdaemon.conf
    chmod 600 ~/.gnupg/scdaemon.conf

    status "Starting GPG agent and initializing card reader..."
    export GPG_TTY=$(tty)
    gpg-connect-agent /bye
    gpg-connect-agent "scd serialno" /bye

    if gpg --card-status 2>/dev/null | grep -q "Signature key\|Encryption key\|Authentication key" && \
       grep -qv "\[none\]" <(gpg --card-status 2>/dev/null | grep "key\.\.\.\.\."); then
        local reset_yubikey=$(gum confirm "Existing keys found on YubiKey. Do you want to reset the YubiKey OpenPGP applet?" --affirmative "Yes" --negative "No" --default=false && echo "true" || echo "false")

        if [[ $reset_yubikey == "true" ]]; then
            status "Resetting YubiKey OpenPGP applet..."
            ykman openpgp reset
            gpg-connect-agent "scd serialno" /bye
            gpgsm --learn
        else
            status "Operation cancelled. YubiKey must be reset to proceed."
            return 1
        fi
    fi

    status "Configuring GPG keys..."
    local key_type="rsa4096"
    local expiration=$(gum input --placeholder "5y" --header "Enter sub key expiration (e.g., 5y for 5 years):")
    local name=$(gum input --header "Enter your name:")
    local email=$(gum input --header "Enter your email:")
    local admin_pin=$(gum input --placeholder "12345678" --header "Enter YubiKey admin PIN (default: 12345678):")
    admin_pin=${admin_pin:-12345678}
    
    status "Generating GPG key..."
    gpg --batch --passphrase '' --quick-generate-key "$name <$email>" $key_type cert never
    key_id=$(gpg -k --with-colons "$name <$email>" | awk -F: '/^pub:/ { print $5; exit }')
    key_fp=$(gpg -k --with-colons "$name <$email>" | awk -F: '/^fpr:/ { print $10; exit }')
    
    status "Generating subkeys..."
    for subkey in sign encrypt auth; do
        gpg --batch --passphrase '' --quick-add-key $key_fp $key_type $subkey $expiration
    done

    status "Creating backups of GPG keys..."
    gpg --output ./secrets/$key_id-Certify.key --armor --export-secret-keys $key_id
    gpg --output ./secrets/$key_id-Subkeys.key --armor --export-secret-subkeys $key_id
    gpg --output ./secrets/$key_id-$(date +%F).asc --armor --export $key_id
    status "GPG key backups created in ./secrets directory"

    if ! unlock_bitwarden; then
        status "Warning: Could not unlock Bitwarden. Skipping key backup."
        echo "Make sure to backup your GPG keys manually."
    else
        local folder_id=$(ensure_folder "YubiKey")
        if [[ -n "$folder_id" ]]; then
            local yubikey_serial=$(ykman info | grep "Serial number:" | awk '{print $3}')
            local note_name="YubiKey GPG Keys - ${yubikey_serial:-Unknown}"
            local note_content="YubiKey Serial: ${yubikey_serial:-Unknown}
GPG Key ID: $key_id
Fingerprint: $key_fp
Created: $(date +%F)"

            local item_id=$(upsert_note "$folder_id" "$note_name" "$note_content")
            if [[ -n "$item_id" ]]; then
                echo "Adding attachments to Bitwarden note $item_id"
                add_attachment "$item_id" "./secrets/$key_id-Certify.key"
                add_attachment "$item_id" "./secrets/$key_id-Subkeys.key"
                add_attachment "$item_id" "./secrets/$key_id-$(date +%F).asc"
                status "GPG keys backed up to Bitwarden"

                if gum confirm "Would you like to remove the local backup files now that they are stored in Bitwarden?"; then
                    rm -f "./secrets/$key_id-Certify.key" "./secrets/$key_id-Subkeys.key" "./secrets/$key_id-$(date +%F).asc"
                    status "Local backup files removed"
                fi
            fi
        fi
    fi

    status "Transferring keys to YubiKey..."
    transfer_subkey() {
        local keynum=$1
        local keytype=$2
        
        expect <<EOF
spawn gpg --edit-key $key_fp
expect "gpg>"
send "key $keynum\r"
expect "gpg>"
send "keytocard\r"
expect "Your selection?"
send "$keytype\r"
expect {
    "Replace existing key?" {
        send "y\r"
        exp_continue
    }
    "PIN" {
        send "$admin_pin\r"
    }
}
expect "gpg>"
send "save\r"
expect eof
EOF
    }
    transfer_subkey 1 1  # Signature key
    transfer_subkey 2 2  # Encryption key
    transfer_subkey 3 3  # Authentication key

    status "Verifying keys on YubiKey..."
    card_status=$(gpg --card-status)
    if echo "$card_status" | grep -q "General key info" && \
       echo "$card_status" | grep -q "Signature key" && \
       echo "$card_status" | grep -q "Encryption key" && \
       echo "$card_status" | grep -q "Authentication key"; then
        status "Keys successfully written to YubiKey."
    else
        status "Error: Keys may not have been properly written to YubiKey. Please check your YubiKey and try again."
        return 1
    fi

    gpg --armor --export $key_fp > ./secrets/gpg-public-key.asc
    status "GPG public key exported to ./secrets/gpg-public-key.asc"

    ssh_public_key=$(gpg --export-ssh-key $key_fp)
    echo "$ssh_public_key" > ~/.ssh/id_rsa_yubikey.pub
    chmod 600 ~/.ssh/id_rsa_yubikey.pub
    status "SSH public key exported to ~/.ssh/id_rsa_yubikey.pub"

    status "Configuring Git to use GPG key for signing..."
    git config --global user.signingkey $key_fp
    git config --global commit.gpgsign true
    git config --global gpg.program $(which gpg)
    git config --global gpg.format openpgp

    status "Configuring YubiKey to require touch for operations..."
    gpg_agent_configuration "pinentry-program" "/usr/bin/pinentry-gnome3" # Set pinentry program to GUI pinentry prompts
    gpg_agent_configuration "allow-loopback-pinentry"
    gpg_agent_configuration "no-grab"
    gpg-connect-agent /bye

    # Set touch policies using ykman with expect
    for policy in sig aut enc; do
        expect << EOF
spawn ykman openpgp keys set-touch $policy on
expect "Enter admin PIN:"
send "$admin_pin\r"
expect "Set touch policy of * key to on? \[y/N\]:"
send "y\r"
expect eof
EOF
    done

    if ! gpg --card-status > /dev/null 2>&1; then
        status "Error: Failed to verify YubiKey configuration. Please check your YubiKey and try again."
        return 1
    fi

    status "YubiKey touch policies configured successfully."

    status "Configuring SSH to use GPG agent..."
    cat << EOF > ~/.ssh/config
Host *
    IdentityFile ~/.ssh/id_rsa_yubikey.pub
EOF

    status "Starting gpg-agent on startup..."
    mkdir -p ~/.config/systemd/user/
    cat << EOF > ~/.config/systemd/user/gpg-agent-restart.service
[Unit]
Description=Restart GPG Agent
After=graphical-session.target
ConditionUser=!root

[Service]
Type=oneshot
ExecStart=/usr/bin/systemctl --user stop gpg-agent.socket gpg-agent.service gpg-agent-ssh.socket gpg-agent-extra.socket gpg-agent-browser.socket
ExecStart=/usr/bin/gpgconf --kill all
ExecStart=/usr/bin/systemctl --user start gpg-agent.socket
ExecStart=/usr/bin/gpg-connect-agent /bye
ExecStart=/usr/bin/gpg-connect-agent updatestartuptty /bye
RemainAfterExit=yes

[Install]
WantedBy=graphical-session.target
EOF

    systemctl --user daemon-reload
    systemctl --user enable gpg-agent-restart.service
    systemctl --user start gpg-agent-restart.service

    status "YubiKey GPG and SSH setup complete."

    local change_pins=$(gum confirm "Do you want to change your YubiKey OpenPGP PINs?" --affirmative "Yes" --negative "No" --default=false && echo "true" || echo "false")
    
    if [[ $change_pins == "true" ]]; then
        gpg_agent_configuration "pinentry-program" "/usr/bin/pinentry-curses" # Temporary pinentry program for unattended operations
        gpg-connect-agent /bye

        local new_user_pin=$(gum input --password --placeholder "123456" --header "Enter new User PIN (min 6 characters):")
        local new_admin_pin=$(gum input --password --placeholder "12345678" --header "Enter new Admin PIN (min 8 characters):")

        if [[ ${#new_user_pin} -lt 6 ]]; then
            status "Error: User PIN must be at least 6 characters long"
            return 1
        fi
        if [[ ${#new_admin_pin} -lt 8 ]]; then
            status "Error: Admin PIN must be at least 8 characters long"
            return 1
        fi

        expect <<EOF
spawn gpg --card-edit
expect "gpg/card>"
send "admin\r"
expect "gpg/card>"
send "passwd\r"
expect "Your selection?"
# Change Admin PIN first
send "3\r"
expect "Enter Admin PIN:"
send "$admin_pin\r"
expect "Enter New Admin PIN:"
send "$new_admin_pin\r"
expect "Repeat New Admin PIN:"
send "$new_admin_pin\r"
expect "PIN changed"
expect "Your selection?"
# Change User PIN
send "1\r"
expect "Enter PIN:"
send "123456\r"
expect "Enter New PIN:"
send "$new_user_pin\r"
expect "Repeat New PIN:"
send "$new_user_pin\r"
expect "PIN changed"
expect "Your selection?"
send "q\r"
expect "gpg/card>"
send "quit\r"
expect eof
EOF

        gpg_agent_configuration "pinentry-program" "/usr/bin/pinentry-gnome3"
        gpg-connect-agent /bye
        status "YubiKey PINs configured successfully"

        if ! unlock_bitwarden; then
            status "Warning: Could not unlock Bitwarden. Skipping PIN backup."
        else
            local folder_id=$(ensure_folder "YubiKey")
            if [[ -n "$folder_id" ]]; then
                local yubikey_serial=$(ykman info | grep "Serial number:" | awk '{print $3}')
                local note_name="YubiKey GPG Keys - ${yubikey_serial:-Unknown}"
                local note_content="YubiKey Serial: ${yubikey_serial:-Unknown}
GPG Key ID: $key_id
Fingerprint: $key_fp
Created: $(date +%F)

User PIN: $new_user_pin
Admin PIN: $new_admin_pin"

                upsert_note "$folder_id" "$note_name" "$note_content"
                status "YubiKey PINs stored in Bitwarden"
            fi
        fi
    fi

    # TODOs
    # - Add touch-detector https://github.com/maximbaz/yubikey-touch-detector
}
