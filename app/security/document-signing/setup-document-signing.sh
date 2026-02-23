source "$MANJIKAZE_DIR/lib/bitwarden.sh"

setup_document_signing_cert() {
    local cert_dir="$HOME/.pdf-signing"
    local p12_file="$cert_dir/signing-cert.p12"

    echo ""
    gum style \
        --border rounded --border-foreground 212 \
        --padding "1 2" --margin "0 1" \
        "📄 10KB Document Signing Certificate" \
        "" \
        "This creates a personal X.509 certificate for signing PDFs" \
        "and other documents, issued by the 10KB Document Signing CA." \
        "" \
        "You will need a Bitwarden Send link from the CA administrator" \
        "containing the CA private key (.key file)." \
        "" \
        "The CA key will be removed from this machine after signing."
    echo ""

    if [[ -f "$p12_file" ]]; then
        if ! gum confirm "A signing certificate already exists at $p12_file. Replace it?" --default=false; then
            status "Keeping existing certificate."
            return 0
        fi
    fi

    # ── Collect user input ─────────────────────────────────────────────
    local name
    name=$(gum input --header "Your full name (as it appears on documents):" --value "$(git config user.name)")
    if [[ -z "$name" ]]; then
        status "Error: Name is required."
        return 1
    fi

    local email
    email=$(gum input --header "Your email address:" --value "$(git config user.email)")
    if [[ -z "$email" ]]; then
        status "Error: Email is required."
        return 1
    fi

    # ── Get CA key via Bitwarden Send ──────────────────────────────────
    if ! gum confirm "Do you have a Bitwarden Send link for the Document Signing CA?" --default=false; then
        status "Ask your CA administrator for a Bitwarden Send link."
        return 1
    fi

    local send_url
    send_url=$(gum input --header "Paste the Bitwarden Send link:" --placeholder "https://vault.bitwarden.com/...")
    if [[ -z "$send_url" ]]; then
        status "Error: Send URL is required."
        return 1
    fi

    local send_password=""
    if gum confirm "Does the Send link require a password?" --default=false; then
        send_password=$(gum input --password --header "Enter the Send password:")
    fi

    # Download CA private key (.key file)
    local ca_key_file
    ca_key_file=$(mktemp)
    local ca_cert_file="$MANJIKAZE_DIR/assets/certs/10kb-document-signing-ca.crt"

    status "Downloading CA key from Bitwarden Send..."
    local receive_cmd="bw send receive \"$send_url\" --output \"$ca_key_file\""
    if [[ -n "$send_password" ]]; then
        receive_cmd="$receive_cmd --password \"$send_password\""
    fi

    if ! eval "$receive_cmd" 2>/dev/null; then
        status "Error: Could not download CA key from Bitwarden Send."
        status "The link may have expired or already been used."
        rm -f "$ca_key_file"
        return 1
    fi

    if [[ ! -f "$ca_cert_file" ]]; then
        status "Error: CA certificate not found at $ca_cert_file."
        rm -f "$ca_key_file"
        return 1
    fi

    # ── Generate developer certificate ─────────────────────────────────
    status "Generating your document signing certificate..."
    mkdir -p "$cert_dir"

    # Generate private key
    openssl genrsa -out "$cert_dir/signing-key.pem" 4096 2>/dev/null

    # Create CSR
    openssl req -new \
        -key "$cert_dir/signing-key.pem" \
        -out "$cert_dir/signing.csr" \
        -subj "/C=NL/O=10KB B.V./CN=$name/emailAddress=$email" \
        2>/dev/null

    # Sign with CA
    openssl x509 -req \
        -in "$cert_dir/signing.csr" \
        -CA "$ca_cert_file" \
        -CAkey "$ca_key_file" \
        -CAcreateserial \
        -out "$cert_dir/signing-cert.pem" \
        -days 1825 \
        -sha256 \
        2>/dev/null

    if [[ $? -ne 0 ]]; then
        status "Error: Failed to sign certificate with CA."
        shred -u "$ca_key_file" 2>/dev/null || rm -f "$ca_key_file"
        return 1
    fi

    # Create PKCS#12 bundle (used by pyHanko for PDF signing)
    local p12_pass
    p12_pass=$(gum input --password --header "Set a password for the .p12 certificate (leave empty for no password):")

    if [[ -n "$p12_pass" ]]; then
        openssl pkcs12 -export \
            -out "$p12_file" \
            -inkey "$cert_dir/signing-key.pem" \
            -in "$cert_dir/signing-cert.pem" \
            -certfile "$ca_cert_file" \
            -name "$name" \
            -passout "pass:$p12_pass" \
            2>/dev/null
    else
        openssl pkcs12 -export \
            -out "$p12_file" \
            -inkey "$cert_dir/signing-key.pem" \
            -in "$cert_dir/signing-cert.pem" \
            -certfile "$ca_cert_file" \
            -name "$name" \
            -passout "pass:" \
            2>/dev/null
    fi

    # ── Cleanup ────────────────────────────────────────────────────────
    # Remove CA private key
    shred -u "$ca_key_file" 2>/dev/null || rm -f "$ca_key_file"

    # Remove CSR and serial file (no longer needed)
    rm -f "$cert_dir/signing.csr"
    rm -f "$MANJIKAZE_DIR/assets/certs/.srl" 2>/dev/null

    # Keep signing-key.pem and signing-cert.pem for reference
    chmod 600 "$cert_dir/signing-key.pem"
    chmod 644 "$cert_dir/signing-cert.pem"
    chmod 600 "$p12_file"

    # ── Backup to Bitwarden ────────────────────────────────────────────
    if ! unlock_bitwarden; then
        status "Warning: Could not unlock Bitwarden. Skipping backup."
        echo "Make sure to backup your signing certificate manually from: $cert_dir"
    else
        local org_id
        org_id=$(get_org_id "10KB")
        if [[ -z "$org_id" ]]; then
            status "Warning: 10KB organization not found in Bitwarden. Skipping backup."
        else
            local bw_user_name
            bw_user_name=$(gum input --header "Your name as it appears in Bitwarden (Medewerkers/...):" --value "$name")
            local collection_id
            collection_id=$(get_user_collection_id "$org_id" "$bw_user_name")

            if [[ -z "$collection_id" ]]; then
                status "Warning: Collection 'Medewerkers/$bw_user_name' not found. Skipping backup."
            else
                local note_name="Document Signing Certificate - $name"
                local note_content="Name: $name
Email: $email
Created: $(date +%F)
Issuer: 10KB Document Signing CA
Valid: 5 years
P12 password: ${p12_pass:-<none>}"

                local item_id
                item_id=$(upsert_org_note "$org_id" "$collection_id" "$note_name" "$note_content")
                if [[ -n "$item_id" ]]; then
                    add_attachment "$item_id" "$p12_file"
                    add_attachment "$item_id" "$cert_dir/signing-key.pem"
                    add_attachment "$item_id" "$cert_dir/signing-cert.pem"
                    status "Document signing certificate backed up to Bitwarden (Medewerkers/$bw_user_name)"
                fi
            fi
        fi
    fi

    # ── Summary ────────────────────────────────────────────────────────
    echo ""
    gum style \
        --border double --border-foreground 76 \
        --padding "1 2" --margin "0 1" \
        "✅ Document signing certificate created" \
        "" \
        "Certificate: $cert_dir/signing-cert.pem" \
        "PKCS#12:     $p12_file" \
        "Subject:     $name <$email>" \
        "Issuer:      10KB Document Signing CA" \
        "Valid:       5 years"
    echo ""
    echo "To sign a PDF (in the documenten repo):"
    echo "  ./sign-pdf.sh document.pdf"
    echo ""
}

setup_document_signing_cert
