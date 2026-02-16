source "$MANJIKAZE_DIR/lib/bitwarden.sh"

# ── Helper: run gpg in non-interactive batch mode ──────────────────────
# Reduces repetition of --command-fd=0 --pinentry-mode=loopback (J)
gpg_batch() {
    gpg --command-fd=0 --pinentry-mode=loopback "$@"
}

yubikey_setup_gpg() {
    local setup_gpg_ssh=$(gum confirm \
        "Do you want to set up GPG and SSH with your YubiKey?

This will:
  • Remove ~/.gnupg (your local GPG keyring and config)
  • Optionally reset the YubiKey OpenPGP applet
  • Generate new GPG keys on THIS machine

⚠ For maximum security, keys should be generated on an
  air-gapped system. This script trades some security for
  convenience by generating on your daily machine." \
        --affirmative "Yes" --negative "No" --default=false && echo "true" || echo "false")

    if [[ "$setup_gpg_ssh" != "true" ]]; then
        return
    fi

    # ── Prerequisites ──────────────────────────────────────────────────
    if ! command -v ykman &> /dev/null; then
        status "ykman (yubikey-manager) is not installed. Please run the essential apps installer first."
        return 1
    fi

    # Detect best pinentry for the current desktop environment
    local pinentry_program
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
        pinentry_program=/usr/bin/pinentry-gnome3
    else
        pinentry_program=/usr/bin/pinentry-gtk
    fi
    status "Using pinentry: $(basename $pinentry_program)"

    if ! ykman list | grep -q "YubiKey"; then
        status "Please insert your YubiKey and try again."
        return 1
    fi

    # ── Stop existing GPG services ─────────────────────────────────────
    status "Stopping any running GPG agent services..."
    systemctl --user stop gpg-agent.socket gpg-agent.service gpg-agent-ssh.socket gpg-agent-extra.socket gpg-agent-browser.socket 2>/dev/null || true
    gpgconf --kill all 2>/dev/null || true

    sudo systemctl restart pcscd
    sleep 2

    # Disable gnome-keyring SSH agent to prevent conflict with gpg-agent
    local gk_desktop="/etc/xdg/autostart/gnome-keyring-ssh.desktop"
    local gk_override="$HOME/.config/autostart/gnome-keyring-ssh.desktop"
    if [[ -f "$gk_desktop" ]] && [[ ! -f "$gk_override" ]]; then
        status "Disabling gnome-keyring SSH agent to avoid conflict with gpg-agent..."
        mkdir -p "$HOME/.config/autostart"
        cp "$gk_desktop" "$gk_override"
        echo "Hidden=true" >> "$gk_override"
    fi

    # ── Fresh GPG configuration ────────────────────────────────────────
    status "Removing existing GPG configuration..."
    rm -rf ~/.gnupg
    mkdir -p ~/.gnupg
    chmod 700 ~/.gnupg

    status "Configuring GPG for YubiKey usage..."
    cp "$MANJIKAZE_DIR/app/security/yubikey/gpg.conf" ~/.gnupg/gpg.conf
    chmod 600 ~/.gnupg/gpg.conf

    # scdaemon: disable-ccid prevents repeated prompts for an already-inserted key
    echo "disable-ccid" > ~/.gnupg/scdaemon.conf
    chmod 600 ~/.gnupg/scdaemon.conf

    # gpg-agent: enable SSH support, use detected pinentry
    cat > ~/.gnupg/gpg-agent.conf <<AGENTCONF
enable-ssh-support
default-cache-ttl 43200
max-cache-ttl 43200
pinentry-program $pinentry_program
allow-loopback-pinentry
allow-preset-passphrase
AGENTCONF
    chmod 600 ~/.gnupg/gpg-agent.conf

    # ── Start GPG agent and verify card ────────────────────────────────
    status "Starting GPG agent and initializing card reader..."
    export GPG_TTY=$(tty)
    gpg-connect-agent /bye
    gpg-connect-agent "scd serialno" /bye

    if ! gpg --card-status > /dev/null 2>&1; then
        status "Error: Cannot read YubiKey. Please check your YubiKey and try again."
        return 1
    fi

    # Check for existing keys on the card by inspecting actual key slots
    # (not "General key info" which depends on the local keyring state)
    local existing_card_status
    existing_card_status=$(gpg --card-status 2>/dev/null)
    local has_existing_keys=false
    if echo "$existing_card_status" | grep "^Signature key" | grep -qv "\[none\]" || \
       echo "$existing_card_status" | grep "^Encryption key" | grep -qv "\[none\]" || \
       echo "$existing_card_status" | grep "^Authentication key" | grep -qv "\[none\]"; then
        has_existing_keys=true
    fi

    if $has_existing_keys; then
        local reset_yubikey=$(gum confirm "Existing keys found on YubiKey. Do you want to reset the YubiKey OpenPGP applet?" --affirmative "Yes" --negative "No" --default=false && echo "true" || echo "false")

        if [[ "$reset_yubikey" == "true" ]]; then
            status "Resetting YubiKey OpenPGP applet..."
            ykman openpgp reset -f
            gpg-connect-agent "scd serialno" /bye
        else
            status "Operation cancelled. YubiKey must be reset to proceed."
            return 1
        fi
    fi

    # ── Collect user input ─────────────────────────────────────────────
    status "Configuring GPG keys..."
    local key_type="rsa4096"
    local expiration
    expiration=$(gum input --placeholder "5y" --header "Enter sub key expiration (e.g., 5y for 5 years):")
    expiration=${expiration:-5y}

    local name
    name=$(gum input --header "Enter your name:")
    if [[ -z "$name" ]]; then
        status "Error: Name is required."
        return 1
    fi

    local email
    email=$(gum input --header "Enter your email:")
    if [[ -z "$email" ]]; then
        status "Error: Email is required."
        return 1
    fi

    local admin_pin
    admin_pin=$(gum input --placeholder "12345678" --header "Enter current YubiKey admin PIN (default: 12345678):")
    admin_pin=${admin_pin:-12345678}

    # Generate a strong passphrase for the certify key
    status "Generating passphrase for the Certify (master) key..."
    local certify_pass
    certify_pass=$(LC_ALL=C tr -dc "A-Z2-9" < /dev/urandom | \
        tr -d "IOUS5" | \
        fold -w 4 | \
        paste -sd - - | \
        head -c 29)
    echo ""
    gum style \
        --border double --border-foreground 212 \
        --padding "1 2" --margin "0 1" \
        "🔑 Certify Key Passphrase (SAVE THIS!)" \
        "" \
        "$certify_pass" \
        "" \
        "This passphrase protects your master key backup." \
        "You will need it to renew or rotate subkeys." \
        "It will be stored in Bitwarden if available."
    echo ""

    if ! gum confirm "Have you saved the Certify key passphrase?" --affirmative "Yes, continue" --negative "Cancel" --default=false; then
        status "Setup cancelled. Please save the passphrase before continuing."
        return 1
    fi

    # Enable KDF before changing PINs or transferring keys
    # KDF stores the hash of PIN on YubiKey, preventing PIN from being sent as plain text
    status "Enabling KDF (Key Derived Function) on YubiKey..."
    gpg_batch --card-edit <<EOF
admin
kdf-setup
$admin_pin
EOF

    # Increase PIN retry counters from default 3 to 5 (User PIN, Reset Code, Admin PIN)
    status "Setting PIN retry counters to 5..."
    ykman openpgp access set-retries 5 5 5 --admin-pin "$admin_pin" --force

    # ── Generate GPG keys ──────────────────────────────────────────────
    status "Generating GPG master key (Certify only)..."
    echo "$certify_pass" | \
        gpg --batch --passphrase-fd 0 \
            --quick-generate-key "$name <$email>" "$key_type" cert never

    local key_id key_fp
    key_id=$(gpg -k --with-colons "$name <$email>" | awk -F: '/^pub:/ { print $5; exit }')
    key_fp=$(gpg -k --with-colons "$name <$email>" | awk -F: '/^fpr:/ { print $10; exit }')

    if [[ -z "$key_fp" ]]; then
        status "Error: Failed to generate GPG key."
        return 1
    fi

    status "Generating subkeys (sign, encrypt, auth)..."
    for subkey in sign encrypt auth; do
        echo "$certify_pass" | \
            gpg --batch --pinentry-mode=loopback --passphrase-fd 0 \
                --quick-add-key "$key_fp" "$key_type" "$subkey" "$expiration"
    done

    # ── Backup keys ────────────────────────────────────────────────────
    status "Creating backups of GPG keys..."
    local secrets_dir="$MANJIKAZE_DIR/secrets"
    local backup_date
    backup_date=$(date +%F)
    mkdir -p "$secrets_dir"

    echo "$certify_pass" | \
        gpg --batch --pinentry-mode=loopback --passphrase-fd 0 \
            --output "$secrets_dir/$key_id-Certify.key" \
            --armor --export-secret-keys "$key_id"
    echo "$certify_pass" | \
        gpg --batch --pinentry-mode=loopback --passphrase-fd 0 \
            --output "$secrets_dir/$key_id-Subkeys.key" \
            --armor --export-secret-subkeys "$key_id"
    gpg --output "$secrets_dir/$key_id-$backup_date.asc" \
        --armor --export "$key_id"

    # Generate revocation certificate
    status "Generating revocation certificate..."
    gpg --pinentry-mode=loopback --passphrase "$certify_pass" \
        --command-fd 0 \
        --gen-revoke --armor --output "$secrets_dir/$key_id-revoke.asc" "$key_id" <<REVEOF
y
1
Revocation certificate generated during YubiKey setup.

y
REVEOF
    chmod 600 "$secrets_dir/$key_id-revoke.asc"

    status "GPG key backups created in $secrets_dir"

    if ! unlock_bitwarden; then
        status "Warning: Could not unlock Bitwarden. Skipping key backup."
        echo "Make sure to backup your GPG keys manually from: $secrets_dir"
    else
        local folder_id
        folder_id=$(ensure_folder "YubiKey")
        if [[ -n "$folder_id" ]]; then
            local yubikey_serial
            yubikey_serial=$(ykman info | grep "Serial number:" | awk '{print $3}')
            local note_name="YubiKey GPG Keys - ${yubikey_serial:-Unknown}"
            local note_content="YubiKey Serial: ${yubikey_serial:-Unknown}
GPG Key ID: $key_id
Fingerprint: $key_fp
Created: $backup_date
Certify Key Passphrase: $certify_pass"

            local item_id
            item_id=$(upsert_note "$folder_id" "$note_name" "$note_content")
            if [[ -n "$item_id" ]]; then
                echo "Adding attachments to Bitwarden note $item_id"
                add_attachment "$item_id" "$secrets_dir/$key_id-Certify.key"
                add_attachment "$item_id" "$secrets_dir/$key_id-Subkeys.key"
                add_attachment "$item_id" "$secrets_dir/$key_id-$backup_date.asc"
                add_attachment "$item_id" "$secrets_dir/$key_id-revoke.asc"
                status "GPG keys and revocation certificate backed up to Bitwarden"

                if gum confirm "Would you like to remove the local backup files now that they are stored in Bitwarden?"; then
                    rm -f "$secrets_dir/$key_id-Certify.key" \
                          "$secrets_dir/$key_id-Subkeys.key" \
                          "$secrets_dir/$key_id-$backup_date.asc" \
                          "$secrets_dir/$key_id-revoke.asc"
                    status "Local backup files removed"
                fi
            fi
        fi
    fi

    # ── Transfer subkeys to YubiKey ────────────────────────────────────
    # GPG 2.x routes ALL PIN/passphrase requests through pinentry, even with
    # --passphrase-fd. We use a temporary custom pinentry that inspects the
    # prompt to determine which secret to provide:
    #   "Admin PIN" prompt → card admin PIN
    #   anything else      → certify key passphrase

    local tmp_pinentry
    tmp_pinentry=$(mktemp)
    cat > "$tmp_pinentry" <<PINENTRY
#!/bin/bash
echo "OK Pleased to meet you"
DESC=""
while IFS= read -r cmd; do
    case "\$cmd" in
        SETDESC*)
            DESC="\${cmd#SETDESC }"
            echo "OK"
            ;;
        GETPIN)
            if echo "\$DESC" | grep -qi "Admin PIN"; then
                echo "D $admin_pin"
            else
                echo "D $certify_pass"
            fi
            echo "OK"
            ;;
        BYE) echo "OK closing connection"; exit 0 ;;
        *) echo "OK" ;;
    esac
done
PINENTRY
    chmod +x "$tmp_pinentry"

    # Swap pinentry temporarily
    sed -i "s|pinentry-program.*|pinentry-program $tmp_pinentry|" ~/.gnupg/gpg-agent.conf
    gpg-connect-agent reloadagent /bye >/dev/null 2>&1

    local -a subkey_labels=("Signature" "Encryption" "Authentication")
    local -a subkey_slots=(1 2 3)

    for i in "${!subkey_labels[@]}"; do
        local label="${subkey_labels[$i]}"
        local slot="${subkey_slots[$i]}"
        status "Transferring $label key to YubiKey (key $((i+1)) → slot $slot)..."

        gpg --command-fd 0 --edit-key "$key_fp" <<EOF
key $((i+1))
keytocard
$slot
save
EOF
    done

    # Restore original pinentry
    sed -i "s|pinentry-program.*|pinentry-program $pinentry_program|" ~/.gnupg/gpg-agent.conf
    gpg-connect-agent reloadagent /bye >/dev/null 2>&1
    rm -f "$tmp_pinentry"

    # ── Verify transfer ────────────────────────────────────────────────
    status "Verifying keys on YubiKey..."
    local card_status
    card_status=$(gpg --card-status 2>&1)
    if echo "$card_status" | grep -q "General key info" && \
       ! echo "$card_status" | grep "Signature key" | grep -q "\[none\]" && \
       ! echo "$card_status" | grep "Encryption key" | grep -q "\[none\]" && \
       ! echo "$card_status" | grep "Authentication key" | grep -q "\[none\]"; then
        status "Keys successfully written to YubiKey."
    else
        status "Error: Keys may not have been properly written to YubiKey. Please check your YubiKey and try again."
        echo "$card_status"
        return 1
    fi

    # ── Set ultimate trust ─────────────────────────────────────────────
    status "Setting ultimate trust on the key..."
    gpg_batch --edit-key "$key_fp" <<EOF
trust
5
y
save
EOF

    # Set login attribute on the card
    status "Setting login attribute on the card..."
    gpg_batch --edit-card <<EOF
admin
login
$name <$email>
$admin_pin
quit
EOF

    # ── Export public key and SSH public key ────────────────────────────
    gpg --armor --export "$key_fp" > "$secrets_dir/gpg-public-key.asc"
    status "GPG public key exported to $secrets_dir/gpg-public-key.asc"

    mkdir -p ~/.ssh
    local ssh_public_key
    ssh_public_key=$(gpg --export-ssh-key "$key_fp")
    echo "$ssh_public_key" > ~/.ssh/id_rsa_yubikey.pub
    chmod 644 ~/.ssh/id_rsa_yubikey.pub
    status "SSH public key exported to ~/.ssh/id_rsa_yubikey.pub"

    # ── Configure Git ──────────────────────────────────────────────────
    status "Configuring Git to use GPG key for signing..."
    git config --global user.signingkey "$key_fp"
    git config --global commit.gpgsign true
    git config --global tag.gpgSign true
    git config --global gpg.program "$(which gpg)"
    git config --global gpg.format openpgp

    # ── Configure touch policies ───────────────────────────────────────
    # 'cached' = touch required, but cached for 15s after use
    # This avoids repeated touches during batch operations (e.g. git rebase)
    status "Configuring YubiKey to require touch for operations (cached 15s)..."
    ykman openpgp keys set-touch sig cached -f -a "$admin_pin"
    ykman openpgp keys set-touch aut cached -f -a "$admin_pin"
    ykman openpgp keys set-touch dec cached -f -a "$admin_pin"

    if ! gpg --card-status > /dev/null 2>&1; then
        status "Error: Failed to verify YubiKey configuration. Please check your YubiKey and try again."
        return 1
    fi

    status "YubiKey touch policies configured successfully."

    # ── SSH config ─────────────────────────────────────────────────────
    status "Configuring SSH to use GPG agent..."
    # Only add YubiKey IdentityFile if not already present
    if [[ ! -f ~/.ssh/config ]] || ! grep -q "id_rsa_yubikey" ~/.ssh/config; then
        cat >> ~/.ssh/config << 'SSHCONF'

# YubiKey GPG-based SSH authentication
Host *
    IdentityFile ~/.ssh/id_rsa_yubikey.pub
SSHCONF
        chmod 600 ~/.ssh/config
    fi

    # ── Shell environment (SSH_AUTH_SOCK, GPG_TTY) ─────────────────────
    # Install as an oh-my-zsh custom plugin so it's loaded automatically.
    # This ensures SSH_AUTH_SOCK is set consistently for both terminal and
    # GUI-launched applications (via systemd import-environment).
    status "Configuring shell environment for GPG/SSH..."
    local plugin_dir="$HOME/.oh-my-zsh/custom/plugins/yubikey-gpg"
    mkdir -p "$plugin_dir"
    cat > "$plugin_dir/yubikey-gpg.plugin.zsh" << 'PLUGINCONF'
# YubiKey GPG agent for SSH
# Sets SSH_AUTH_SOCK to the gpg-agent SSH socket so that ssh, git, etc.
# use the GPG agent (and thus the YubiKey) for authentication.

export GPG_TTY=$(tty)
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

# Make sure gpg-agent is running
gpgconf --launch gpg-agent

# Update the TTY for the current session (important for pinentry)
gpg-connect-agent updatestartuptty /bye > /dev/null 2>&1
PLUGINCONF

    # Activate the plugin via oh-my-zsh
    activate_zsh_plugin "yubikey-gpg"

    # Also export to systemd user environment so GUI apps pick it up
    systemctl --user import-environment SSH_AUTH_SOCK GPG_TTY 2>/dev/null || true

    # ── Systemd gpg-agent socket activation ────────────────────────────
    # Start the gpg-agent sockets — they are socket-activated (auto-started on
    # demand) so no 'enable' is needed; just starting them is sufficient.
    status "Starting gpg-agent socket activation..."
    systemctl --user start gpg-agent.socket gpg-agent-ssh.socket 2>/dev/null || true

    status "YubiKey GPG and SSH setup complete."

    # ── Change PINs (strongly recommended) ──────────────────────────────
    # The User PIN is needed once per day to unlock the YubiKey for SSH,
    # Git signing, and other GPG operations. Changing it from the default
    # (123456) is essential.
    local change_pins=$(gum confirm \
        "Change your YubiKey PINs? (Strongly recommended)

Your User PIN unlocks the YubiKey for daily use (SSH, Git, GPG).
The default PIN (123456) is insecure and should be changed.
Choose a PIN you can remember — you'll enter it once per day." \
        --affirmative "Yes, change PINs" --negative "Skip" --default=true && echo "true" || echo "false")

    if [[ "$change_pins" == "true" ]]; then
        local current_user_pin
        current_user_pin=$(gum input --password --placeholder "123456" --header "Enter CURRENT User PIN (default after reset: 123456):")
        current_user_pin=${current_user_pin:-123456}

        local new_user_pin
        new_user_pin=$(gum input --password --placeholder "" --header "Enter new User PIN (min 6 characters):")
        local new_admin_pin
        new_admin_pin=$(gum input --password --placeholder "" --header "Enter new Admin PIN (min 8 characters):")

        if [[ ${#new_user_pin} -lt 6 ]]; then
            status "Error: User PIN must be at least 6 characters long"
            return 1
        fi
        if [[ ${#new_admin_pin} -lt 8 ]]; then
            status "Error: Admin PIN must be at least 8 characters long"
            return 1
        fi

        # Change Admin PIN first (option 3)
        status "Changing Admin PIN..."
        gpg_batch --change-pin <<EOF
3
$admin_pin
$new_admin_pin
$new_admin_pin
q
EOF

        # Change User PIN (option 1)
        status "Changing User PIN..."
        gpg_batch --change-pin <<EOF
1
$current_user_pin
$new_user_pin
$new_user_pin
q
EOF

        status "YubiKey PINs configured successfully"

        # (G) Store PINs in Bitwarden with explicit warning on failure
        if ! unlock_bitwarden; then
            status "⚠ WARNING: Could not unlock Bitwarden. Your new PINs are NOT backed up!"
            echo ""
            echo "  Please write down your new PINs in a secure location NOW:"
            echo "  User PIN:  (the value you just entered)"
            echo "  Admin PIN: (the value you just entered)"
            echo ""
            gum confirm "I have saved my PINs" --affirmative "Yes, continue" --default=false || true
        else
            local folder_id
            folder_id=$(ensure_folder "YubiKey")
            if [[ -n "$folder_id" ]]; then
                local yubikey_serial
                yubikey_serial=$(ykman info | grep "Serial number:" | awk '{print $3}')
                local note_name="YubiKey GPG Keys - ${yubikey_serial:-Unknown}"
                local note_content="YubiKey Serial: ${yubikey_serial:-Unknown}
GPG Key ID: $key_id
Fingerprint: $key_fp
Created: $backup_date
Certify Key Passphrase: $certify_pass

User PIN: $new_user_pin
Admin PIN: $new_admin_pin"

                upsert_note "$folder_id" "$note_name" "$note_content"
                status "YubiKey PINs stored in Bitwarden"
            fi
        fi
    fi

    # ── Summary ────────────────────────────────────────────────────────
    echo ""
    gum style \
        --border double --border-foreground 76 \
        --padding "1 2" --margin "0 1" \
        "✅ YubiKey GPG and SSH setup complete" \
        "" \
        "GPG Key:        $key_id" \
        "Fingerprint:    $key_fp" \
        "SSH public key: ~/.ssh/id_rsa_yubikey.pub"
    echo ""
    echo "To use in a new terminal session, restart your shell or run:"
    echo "  source ~/.oh-my-zsh/custom/plugins/yubikey-gpg/yubikey-gpg.plugin.zsh"
    echo ""
    echo "To test SSH authentication:"
    echo "  ssh-add -L"
    echo ""
    echo "To add your GPG key to GitHub/GitLab:"
    echo "  cat $secrets_dir/gpg-public-key.asc"
    echo ""
    echo "To add your SSH key to GitHub/GitLab:"
    echo "  cat ~/.ssh/id_rsa_yubikey.pub"
    echo ""
}

yubikey_setup_gpg
