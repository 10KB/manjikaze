#!/bin/bash

source "$MANJIKAZE_DIR/lib/bitwarden.sh"
source "$MANJIKAZE_DIR/lib/gpg.sh"
source "$MANJIKAZE_DIR/lib/common.sh"

yubikey_gpg_configure_machine() {
    local confirm
    confirm=$(gum confirm \
        "Configure this machine to use an existing YubiKey for GPG/SSH?

This will:
  • Remove ~/.gnupg (your local GPG keyring and config)
  • Download your public key (from Keyserver, Bitwarden or local file)
  • Link your YubiKey to the public key
  • Configure Git and SSH to use the YubiKey

The YubiKey itself will NOT be modified." \
        --affirmative "Yes" --negative "No" --default=false && echo "true" || echo "false")

    if [[ "$confirm" != "true" ]]; then return; fi

    # ── Prerequisites ──────────────────────────────────────────────────
    if ! command -v ykman &> /dev/null; then
        status "ykman not installed. Please run the essential apps installer first."
        return 1
    fi

    if ! ykman list | grep -q "YubiKey"; then
        status "Please insert your YubiKey and try again."
        return 1
    fi

    # ── Stop existing GPG services and setup ───────────────────────────
    setup_gpg_config

    if ! gpg --card-status > /dev/null 2>&1; then
        status "Error: Cannot read YubiKey. Please check your YubiKey and try again."
        return 1
    fi

    local yk_serial
    yk_serial=$(ykman info | grep "Serial number:" | awk '{print $3}')
    status "Detected YubiKey (Serial: ${yk_serial:-unknown})"

    # ── Fetch Public Key ───────────────────────────────────────────────
    status "We need your GPG public key to configure the machine."
    local source
    source=$(gum choose "Keyserver (keys.openpgp.org)" "Bitwarden" "Local file")

    local key_fp=""
    local key_id=""

    if [[ "$source" == "Bitwarden" ]]; then
        if ! unlock_bitwarden; then
            status "Error: Could not unlock Bitwarden."
            return 1
        fi

        # Find YubiKey GPG notes
        local items
        items=$(bw list items --search "YubiKey GPG Keys" --session "$BW_SESSION" 2>/dev/null)
        if [[ -z "$items" || "$items" == "[]" ]]; then
            status "Error: No YubiKey GPG backup found in Bitwarden."
            return 1
        fi

        local note_names
        note_names=$(echo "$items" | jq -r '.[].name')
        local selected
        selected=$(echo "$note_names" | gum choose --header "Select backup to grab public key from:")
        local item_id
        item_id=$(echo "$items" | jq -r --arg name "$selected" '.[] | select(.name == $name) | .id')

        if [[ -z "$item_id" ]]; then
            status "Error: Could not find selected backup."
            return 1
        fi

        local attachments
        attachments=$(echo "$items" | jq -r --arg name "$selected" '.[] | select(.name == $name) | .attachments[]?.fileName')

        # Look for the .asc file that is not the revoke one
        local pubkey_file
        pubkey_file=$(echo "$attachments" | grep "\.asc" | grep -v "revoke" | head -1)

        if [[ -z "$pubkey_file" ]]; then
            status "Error: No public key (.asc) attachment found in this Bitwarden item."
            return 1
        fi

        local tmp_pub
        tmp_pub=$(mktemp)
        bw get attachment "$pubkey_file" --itemid "$item_id" --output "$tmp_pub" --session "$BW_SESSION"

        # Import it
        status "Importing public key from Bitwarden..."
        gpg --import "$tmp_pub" 2>&1 | grep "imported"
        rm -f "$tmp_pub"

    elif [[ "$source" == "Local file" ]]; then
        local secrets_dir="$MANJIKAZE_DIR/secrets"
        local key_files
        key_files=$(find "$secrets_dir" -name "*.asc" -not -name "*revoke*.asc" 2>/dev/null)

        if [[ -z "$key_files" ]]; then
            status "Error: No .asc public key files found in $secrets_dir"
            return 1
        fi

        local selected_file
        selected_file=$(echo "$key_files" | gum choose --header "Select public key file:")

        status "Importing public key from local file..."
        gpg --import "$selected_file" 2>&1 | grep "imported"

    elif [[ "$source" == "Keyserver (keys.openpgp.org)" ]]; then
        local search_term
        search_term=$(gum input --placeholder "Email or Fingerprint" --header "Search keys.openpgp.org for:")
        if [[ -z "$search_term" ]]; then
            status "Error: Search term required."
            return 1
        fi

        status "Searching keyserver and importing..."
        if ! gpg --keyserver hkps://keys.openpgp.org --search-keys "$search_term"; then
            status "Error: Failed to fetch key from keyserver."
            return 1
        fi
    fi

    # ── Setup card stubs ───────────────────────────────────────────────
    status "Updating local keyring to use YubiKey (creating stubs)..."
    gpg --card-status >/dev/null 2>&1

    # Get key fingerprint
    key_fp=$(gpg -k --with-colons 2>/dev/null | awk -F: '/^fpr:/ { print $10; exit }')
    key_id=$(gpg -k --with-colons 2>/dev/null | awk -F: '/^pub:/ { print $5; exit }')

    if [[ -z "$key_fp" ]]; then
        status "Error: Could not find any imported public keys in the keyring."
        return 1
    fi

    status "Selected Key: $key_id (${key_fp:0:4} ... ${key_fp: -4})"

    # ── Set ultimate trust ─────────────────────────────────────────────
    status "Setting ultimate trust on the key..."
    gpg_batch --edit-key "$key_fp" <<EOF
trust
5
y
save
EOF

    # ── Export SSH public key ──────────────────────────────────────────
    status "Exporting SSH public key to ~/.ssh/id_rsa_yubikey.pub"
    mkdir -p ~/.ssh
    gpg --export-ssh-key "$key_fp" > ~/.ssh/id_rsa_yubikey.pub
    chmod 644 ~/.ssh/id_rsa_yubikey.pub

    # ── Configure Git and Shell Environment ────────────────────────────
    configure_git_gpg "$key_fp"
    configure_shell_env

    # ── Configure Automatic PIN Entry ──────────────────────────────────
    configure_automatic_pin_entry

    # ── Summary ────────────────────────────────────────────────────────
    echo ""
    gum style \
        --border double --border-foreground 76 \
        --padding "1 2" --margin "0 1" \
        "✅ Machine configured successfully for YubiKey" \
        "" \
        "GPG Key:        $key_id" \
        "Fingerprint:    $key_fp" \
        "SSH public key: ~/.ssh/id_rsa_yubikey.pub"
    echo ""
    echo "To use in a new terminal session, restart your shell or run:"
    echo "  source ~/.oh-my-zsh/custom/plugins/yubikey-gpg/yubikey-gpg.plugin.zsh"
    echo ""
    echo "To test SSH authentication (make sure YubiKey is touched if blinking):"
    echo "  ssh-add -L"
    echo ""
}

yubikey_gpg_configure_machine
