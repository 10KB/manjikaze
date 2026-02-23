unlock_bitwarden() {
    local bw_status
    bw_status=$(bw status 2>/dev/null | jq -r '.status' 2>/dev/null)

    if [[ "$bw_status" == "unlocked" ]]; then
        # Already unlocked — BW_SESSION should be set from a previous call
        if [[ -n "$BW_SESSION" ]]; then
            return 0
        fi
    fi

    if [[ "$bw_status" == "unauthenticated" ]]; then
        status "Bitwarden vault is not logged in."
        if ! gum confirm "Log in to Bitwarden now?" --affirmative "Yes" --negative "Skip" --default=false; then
            return 1
        fi

        local bw_email
        bw_email=$(gum input --placeholder "user@example.com" --header "Bitwarden email address:")
        if [[ -z "$bw_email" ]]; then
            status "No email provided. Skipping Bitwarden."
            return 1
        fi

        local bw_master
        bw_master=$(gum input --password --header "Bitwarden master password:")
        if [[ -z "$bw_master" ]]; then
            status "No password provided. Skipping Bitwarden."
            return 1
        fi

        export BW_PASSWORD="$bw_master"

        # Check if 2FA is needed
        local bw_2fa_code=""
        if gum confirm "Do you have 2FA enabled on Bitwarden?" --affirmative "Yes" --negative "No" --default=true; then
            bw_2fa_code=$(gum input --placeholder "123456" --header "Enter 2FA code from authenticator app:")
        fi

        if [[ -n "$bw_2fa_code" ]]; then
            BW_SESSION=$(bw login "$bw_email" --passwordenv BW_PASSWORD --code "$bw_2fa_code" --method 0 --raw 2>/dev/null)
        else
            BW_SESSION=$(bw login "$bw_email" --passwordenv BW_PASSWORD --raw 2>/dev/null)
        fi
        unset BW_PASSWORD
        export BW_SESSION

        if [[ -z "$BW_SESSION" ]]; then
            status "Failed to log in to Bitwarden. Check your credentials."
            return 1
        fi

        bw sync --session "$BW_SESSION" >/dev/null 2>&1 || true
        status "Bitwarden login successful."
        return 0
    fi

    status "Bitwarden vault is locked. Attempting to unlock..."
    local master_password
    master_password=$(gum input --password --prompt "Enter your Bitwarden master password: ")

    # Use --passwordenv per Bitwarden CLI docs
    export BW_PASSWORD="$master_password"
    BW_SESSION=$(bw unlock --passwordenv BW_PASSWORD --raw 2>/dev/null)
    unset BW_PASSWORD
    export BW_SESSION

    if [[ -z "$BW_SESSION" ]]; then
        status "Failed to unlock Bitwarden vault."
        return 1
    fi

    # Sync vault data after unlocking
    bw sync --session "$BW_SESSION" >/dev/null 2>&1 || true
}

# ── Organization helpers ───────────────────────────────────────────────

get_org_id() {
    local org_name="${1:-10KB}"
    bw list organizations --session "$BW_SESSION" 2>/dev/null \
        | jq -r ".[] | select(.name==\"$org_name\") | .id"
}

get_user_collection_id() {
    local org_id="$1"
    local user_name="$2"
    local collection_path="Medewerkers/${user_name}"

    bw list org-collections --organizationid "$org_id" --session "$BW_SESSION" 2>/dev/null \
        | jq -r ".[] | select(.name==\"$collection_path\") | .id"
}

upsert_org_note() {
    local org_id="$1"
    local collection_id="$2"
    local note_name="$3"
    local note_content="$4"

    # Search for existing item in the organization
    local existing_item
    existing_item=$(bw list items --organizationid "$org_id" --collectionid "$collection_id" \
        --session "$BW_SESSION" 2>/dev/null \
        | jq -r ".[] | select(.name==\"$note_name\") | .id")

    local item_id

    if [[ -n "$existing_item" ]]; then
        bw get item "$existing_item" --session "$BW_SESSION" | \
            jq --arg notes "$note_content" '.notes = $notes' | \
            bw encode | \
            bw edit item "$existing_item" --session "$BW_SESSION" > /dev/null
        item_id="$existing_item"
    else
        item_id=$(bw get template item | \
            jq --arg name "$note_name" \
               --arg org_id "$org_id" \
               --arg coll_id "$collection_id" \
               --arg notes "$note_content" \
            '.type = 2 | .secureNote.type = 0 | .name = $name | .organizationId = $org_id | .collectionIds = [$coll_id] | .notes = $notes' | \
            bw encode | \
            bw create item --session "$BW_SESSION" | jq -r '.id')
    fi
    echo "$item_id"
}

add_attachment() {
    local item_id="$1"
    local file_path="$2"

    if [[ ! -f "$file_path" ]]; then
        status "Error: File not found: $file_path"
        return 1
    fi

    status "Adding attachment: $(basename "$file_path")..."
    bw create attachment --file "$file_path" --itemid "$item_id" --session "$BW_SESSION" > /dev/null
}

# ── Legacy folder-based helpers (backward compatibility) ───────────────

ensure_folder() {
    local folder_name="$1"

    local folder_id
    folder_id=$(bw list folders --session "$BW_SESSION" | jq -r ".[] | select(.name==\"$folder_name\") | .id")
    if [[ -z "$folder_id" ]]; then
        status "Creating '$folder_name' folder in Bitwarden..."
        folder_id=$(bw get template folder | jq --arg name "$folder_name" '.name=$name' | bw encode | bw create folder --session "$BW_SESSION" | jq -r '.id')
        if [[ -z "$folder_id" ]]; then
            status "Failed to create '$folder_name' folder in Bitwarden."
            return 1
        fi
    fi
    echo "$folder_id"
}

upsert_note() {
    local folder_id="$1"
    local note_name="$2"
    local note_content="$3"

    local existing_item
    existing_item=$(bw list items --folderid "$folder_id" --session "$BW_SESSION" | jq -r ".[] | select(.name==\"$note_name\") | .id")

    local item_id

    if [[ -n "$existing_item" ]]; then
        bw get item "$existing_item" --session "$BW_SESSION" | \
            jq --arg notes "$note_content" '.notes = $notes' | \
            bw encode | \
            bw edit item "$existing_item" --session "$BW_SESSION" > /dev/null
        item_id="$existing_item"
    else
        item_id=$(bw get template item | \
            jq --arg name "$note_name" \
               --arg folder_id "$folder_id" \
               --arg notes "$note_content" \
            '.type = 2 | .secureNote.type = 0 | .name = $name | .folderId = $folder_id | .notes = $notes' | \
            bw encode | \
            bw create item --session "$BW_SESSION" | jq -r '.id')
    fi
    echo "$item_id"
}
