source "$MANJIKAZE_DIR/lib/bitwarden.sh"

source "$MANJIKAZE_DIR/lib/gpg.sh"

yubikey_gpg_restore() {
    local confirm=$(gum confirm \
        "Restore GPG keys to a NEW YubiKey?

This will:
  • Retrieve key backups from Bitwarden or local files
  • Import master key into a temporary keyring
  • Transfer subkeys to the new YubiKey
  • Update your local GPG keyring to use the new card

Your existing ~/.gnupg configuration will be preserved." \
        --affirmative "Yes" --negative "No" --default=false && echo "true" || echo "false")

    if [[ "$confirm" != "true" ]]; then return; fi

    # ── Prerequisites ──────────────────────────────────────────────────
    if ! command -v ykman &>/dev/null; then
        status "ykman not installed. Run the essential apps installer first."
        return 1
    fi

    if ! ykman list | grep -q "YubiKey"; then
        status "Please insert your NEW YubiKey and try again."
        return 1
    fi

    local yk_serial
    yk_serial=$(ykman info | grep "Serial number:" | awk '{print $3}')
    status "Detected YubiKey (Serial: ${yk_serial:-unknown})"

    # ── Choose backup source ───────────────────────────────────────────
    local secrets_dir="$MANJIKAZE_DIR/secrets"
    local source
    source=$(gum choose "Bitwarden" "Local files ($secrets_dir)")

    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap "rm -rf '$tmp_dir'" EXIT

    local certify_key="" certify_pass="" key_id="" key_fp=""

    if [[ "$source" == "Bitwarden" ]]; then
        if ! unlock_bitwarden; then
            status "Error: Could not unlock Bitwarden."
            return 1
        fi

        # Find YubiKey GPG notes
        local items
        items=$(bw list items --search "YubiKey GPG Keys" --session "$BW_SESSION" 2>/dev/null)
        if [[ -z "$items" || "$items" == "[]" ]]; then
            status "No YubiKey GPG backup found in Bitwarden."
            return 1
        fi

        # Let user choose if multiple
        local note_names
        note_names=$(echo "$items" | jq -r '.[].name')
        local selected
        selected=$(echo "$note_names" | gum choose --header "Select backup to restore:")
        local item_id
        item_id=$(echo "$items" | jq -r --arg name "$selected" '.[] | select(.name == $name) | .id')

        if [[ -z "$item_id" ]]; then
            status "Error: Could not find selected backup."
            return 1
        fi

        # Extract passphrase from note content
        local note_content
        note_content=$(echo "$items" | jq -r --arg name "$selected" '.[] | select(.name == $name) | .notes')
        certify_pass=$(echo "$note_content" | grep "Certify Key Passphrase:" | awk '{print $NF}')
        key_id=$(echo "$note_content" | grep "GPG Key ID:" | awk '{print $NF}')

        if [[ -z "$certify_pass" ]]; then
            status "Warning: Passphrase not found in Bitwarden note."
            certify_pass=$(gum input --password --header "Enter Certify key passphrase:")
        fi

        # Download Certify.key attachment
        local attachments
        attachments=$(echo "$items" | jq -r --arg name "$selected" '.[] | select(.name == $name) | .attachments[]?.fileName')

        local certify_file
        certify_file=$(echo "$attachments" | grep "Certify.key" | head -1)
        if [[ -z "$certify_file" ]]; then
            status "Error: No Certify.key attachment found."
            return 1
        fi

        bw get attachment "$certify_file" --itemid "$item_id" \
            --output "$tmp_dir/Certify.key" --session "$BW_SESSION"
        certify_key="$tmp_dir/Certify.key"

    else
        # Local files
        if [[ ! -d "$secrets_dir" ]]; then
            status "Error: No secrets directory at $secrets_dir"
            return 1
        fi

        # Find Certify.key files
        local key_files
        key_files=$(find "$secrets_dir" -name "*-Certify.key" 2>/dev/null)
        if [[ -z "$key_files" ]]; then
            status "Error: No Certify.key files found in $secrets_dir"
            return 1
        fi

        local selected_file
        selected_file=$(echo "$key_files" | gum choose --header "Select key backup:")
        certify_key="$selected_file"

        # Extract key ID from filename (format: KEYID-Certify.key)
        key_id=$(basename "$selected_file" | sed 's/-Certify\.key$//')

        certify_pass=$(gum input --password --header "Enter Certify key passphrase:")
    fi

    if [[ ! -f "$certify_key" ]]; then
        status "Error: Certify key file not found."
        return 1
    fi

    if [[ -z "$certify_pass" ]]; then
        status "Error: Passphrase is required."
        return 1
    fi

    # ── Admin PIN ──────────────────────────────────────────────────────
    local admin_pin
    admin_pin=$(gum input --placeholder "12345678" \
        --header "Enter admin PIN for the NEW YubiKey (default: 12345678):")
    admin_pin=${admin_pin:-12345678}

    # ── Reset new YubiKey ──────────────────────────────────────────────
    if ! gum confirm "Reset OpenPGP applet on new YubiKey? (Recommended for a fresh start)" \
        --affirmative "Yes, reset" --negative "Skip" --default=false; then
        status "Skipping reset. Existing keys will be overwritten."
    else
        status "Resetting OpenPGP applet..."
        ykman openpgp reset -f
        admin_pin="12345678"
        status "Reset complete. Admin PIN reset to default: 12345678"
    fi

    # ── Import into temporary keyring ──────────────────────────────────
    status "Importing keys into temporary keyring..."
    local real_gnupghome="$GNUPGHOME"
    [[ -z "$real_gnupghome" ]] && real_gnupghome="$HOME/.gnupg"

    local tmp_gnupg="$tmp_dir/gnupg"
    mkdir -p "$tmp_gnupg"
    chmod 700 "$tmp_gnupg"

    # Copy config from real home
    for cfg in gpg.conf scdaemon.conf gpg-agent.conf; do
        [[ -f "$real_gnupghome/$cfg" ]] && cp "$real_gnupghome/$cfg" "$tmp_gnupg/"
    done

    export GNUPGHOME="$tmp_gnupg"
    export GPG_TTY=$(tty)

    # Start agent in temp context
    gpgconf --kill all 2>/dev/null || true
    gpg-connect-agent /bye 2>/dev/null
    gpg-connect-agent "scd serialno" /bye 2>/dev/null

    # Import the full key
    echo "$certify_pass" | \
        gpg --batch --pinentry-mode=loopback --passphrase-fd 0 \
            --import "$certify_key" 2>&1

    if [[ $? -ne 0 ]]; then
        export GNUPGHOME="$real_gnupghome"
        status "Error: Failed to import key. Check the passphrase."
        return 1
    fi

    # Get key details from imported key
    key_fp=$(gpg -k --with-colons 2>/dev/null | awk -F: '/^fpr:/ { print $10; exit }')
    key_id=$(gpg -k --with-colons 2>/dev/null | awk -F: '/^pub:/ { print $5; exit }')

    if [[ -z "$key_fp" ]]; then
        export GNUPGHOME="$real_gnupghome"
        status "Error: Could not read imported key."
        return 1
    fi

    status "Imported key: $key_id (${key_fp:0:4} ... ${key_fp: -4})"

    # ── Enable KDF ─────────────────────────────────────────────────────
    status "Enabling KDF on new YubiKey..."
    gpg_batch --card-edit <<EOF
admin
kdf-setup
$admin_pin
EOF

    # ── Transfer subkeys to new YubiKey ────────────────────────────────
    # Use a custom pinentry to provide key passphrase + admin PIN
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

    sed -i "s|pinentry-program.*|pinentry-program $tmp_pinentry|" "$GNUPGHOME/gpg-agent.conf"
    gpg-connect-agent reloadagent /bye >/dev/null 2>&1

    local -a subkey_labels=("Signature" "Encryption" "Authentication")
    local -a subkey_slots=(1 2 3)

    for i in "${!subkey_labels[@]}"; do
        local label="${subkey_labels[$i]}"
        local slot="${subkey_slots[$i]}"
        status "Transferring $label key (key $((i+1)) → slot $slot)..."
        gpg --command-fd 0 --edit-key "$key_fp" <<EOF
key $((i+1))
keytocard
$slot
save
EOF
    done

    # Restore original pinentry
    local pinentry_program
    pinentry_program=$(get_pinentry_program)
    sed -i "s|pinentry-program.*|pinentry-program $pinentry_program|" "$GNUPGHOME/gpg-agent.conf"
    gpg-connect-agent reloadagent /bye >/dev/null 2>&1
    rm -f "$tmp_pinentry"

    # ── Verify transfer ────────────────────────────────────────────────
    status "Verifying keys on new YubiKey..."
    local card_status
    card_status=$(gpg --card-status 2>&1)
    if echo "$card_status" | grep -q "General key info" && \
       ! echo "$card_status" | grep "Signature key" | grep -q "\[none\]" && \
       ! echo "$card_status" | grep "Encryption key" | grep -q "\[none\]" && \
       ! echo "$card_status" | grep "Authentication key" | grep -q "\[none\]"; then
        status "Keys successfully written to new YubiKey."
    else
        export GNUPGHOME="$real_gnupghome"
        status "Error: Key transfer may have failed."
        echo "$card_status"
        return 1
    fi

    # ── Set touch policies ─────────────────────────────────────────────
    status "Setting touch policies..."
    ykman openpgp keys set-touch sig on -f -a "$admin_pin"
    ykman openpgp keys set-touch aut on -f -a "$admin_pin"
    ykman openpgp keys set-touch dec on -f -a "$admin_pin"

    # ── Set login attribute ────────────────────────────────────────────
    local uid
    uid=$(gpg -k --with-colons 2>/dev/null | awk -F: '/^uid:/ { print $10; exit }')
    if [[ -n "$uid" ]]; then
        status "Setting login attribute: $uid"
        gpg_batch --edit-card <<EOF
admin
login
$uid
$admin_pin
quit
EOF
    fi

    # ── Update real keyring ────────────────────────────────────────────
    status "Updating local keyring to use new card..."

    # Export public key from temp keyring
    gpg --armor --export "$key_fp" > "$tmp_dir/public.asc"

    # Switch back to real keyring
    gpgconf --kill all 2>/dev/null || true
    export GNUPGHOME="$real_gnupghome"
    gpgconf --kill all 2>/dev/null || true

    # Remove old secret key stubs (they point to old card)
    gpg --batch --yes --delete-secret-keys "$key_fp" 2>/dev/null || true

    # Import public key (if not already present)
    gpg --import "$tmp_dir/public.asc" 2>/dev/null

    # Restart agent and pick up new card
    gpg-connect-agent /bye 2>/dev/null
    gpg-connect-agent "scd serialno" /bye 2>/dev/null

    # card-status auto-creates new stubs pointing to new card
    gpg --card-status >/dev/null 2>&1

    # Restore ultimate trust
    gpg_batch --edit-key "$key_fp" <<EOF
trust
5
y
save
EOF

    # ── Optional: Change PINs ──────────────────────────────────────────
    local new_user_pin=""
    if gum confirm "Change PINs on the new YubiKey?" \
        --affirmative "Yes" --negative "No" --default=false; then

        local new_admin_pin
        new_user_pin=$(gum input --password --header "New User PIN (min 6 chars):")
        new_admin_pin=$(gum input --password --header "New Admin PIN (min 8 chars):")

        if [[ ${#new_user_pin} -lt 6 ]]; then
            status "Error: User PIN too short"; return 1
        fi
        if [[ ${#new_admin_pin} -lt 8 ]]; then
            status "Error: Admin PIN too short"; return 1
        fi

        gpg_batch --change-pin <<EOF
3
$admin_pin
$new_admin_pin
$new_admin_pin
q
EOF
        gpg_batch --change-pin <<EOF
1
123456
$new_user_pin
$new_user_pin
q
EOF
        status "PINs changed successfully."

        # Update Bitwarden
        if unlock_bitwarden; then
            local folder_id
            folder_id=$(ensure_folder "YubiKey")
            if [[ -n "$folder_id" ]]; then
                local note_name="YubiKey GPG Keys - ${yk_serial:-Unknown}"
                local note_content="YubiKey Serial: ${yk_serial:-Unknown}
GPG Key ID: $key_id
Fingerprint: $key_fp
Restored: $(date +%F)
Certify Key Passphrase: $certify_pass

User PIN: $new_user_pin
Admin PIN: $new_admin_pin"
                upsert_note "$folder_id" "$note_name" "$note_content"
                status "New PINs stored in Bitwarden."
            fi
        else
            status "⚠ WARNING: Could not save PINs to Bitwarden!"
            echo "  Write down your PINs in a secure location NOW."
            gum confirm "I have saved my PINs" --affirmative "Yes" --default=false || true
        fi
    fi

    local pin_to_save="123456"
    if [[ -n "$new_user_pin" ]]; then
        pin_to_save="$new_user_pin"
    fi
    configure_automatic_pin_entry "$pin_to_save"

    # ── Verify final state ─────────────────────────────────────────────
    status "Running final verification..."
    local final_status
    final_status=$(gpg --card-status 2>&1)
    local ssh_key
    ssh_key=$(gpg --export-ssh-key "$key_fp" 2>/dev/null)

    # Update SSH public key file
    if [[ -n "$ssh_key" ]]; then
        mkdir -p ~/.ssh
        echo "$ssh_key" > ~/.ssh/id_rsa_yubikey.pub
        chmod 644 ~/.ssh/id_rsa_yubikey.pub
        status "SSH public key updated."
    fi

    echo ""
    gum style \
        --border double --border-foreground 76 \
        --padding "1 2" --margin "0 1" \
        "✅ YubiKey GPG restore complete" \
        "" \
        "GPG Key:        $key_id" \
        "Fingerprint:    $key_fp" \
        "New YubiKey:    Serial ${yk_serial:-unknown}"
    echo ""
    echo "Verify with:  gpg --card-status"
    echo "Test SSH:     ssh-add -L"
    echo ""
}

yubikey_gpg_restore
