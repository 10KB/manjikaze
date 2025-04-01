unlock_bitwarden() {
    local bw_status=$(bw status | jq -r '.status')
    if [[ "$bw_status" != "unlocked" ]]; then
        status "Bitwarden vault is locked. Attempting to unlock..."
        master_password=$(gum input --password --prompt "Enter your Bitwarden master password: ")

        export BW_PASSWORD="$master_password"

        unlock_output=$(bw unlock --passwordenv BW_PASSWORD --raw)

        if [ $? -eq 0 ]; then
            export BW_SESSION="$unlock_output"
            status "Bitwarden vault unlocked successfully."
        else
            status "Failed to unlock Bitwarden vault. Please try again."
            unset BW_PASSWORD
            return 1
        fi

        unset BW_PASSWORD
    else
        status "Bitwarden vault is already unlocked."
    fi
    return 0
}

ensure_folder() {
    local folder_name="$1"

    local folder_id=$(bw list folders | jq -r ".[] | select(.name==\"$folder_name\") | .id")
    if [[ -z "$folder_id" ]]; then
        status "Creating '$folder_name' folder in Bitwarden..."
        local creation_output
        creation_output=$(bw get template folder | jq --arg name "$folder_name" '.name=$name' | bw encode | bw create folder)
        if [[ $? -ne 0 ]]; then
            status "Failed to execute 'bw create folder' for '$folder_name'."
            return 1
        fi
        folder_id=$(echo "$creation_output" | jq -r '.id')
        if [[ -z "$folder_id" || "$folder_id" == "null" ]]; then
            status "Failed to create '$folder_name' folder in Bitwarden (ID not found)."
            return 1
        fi
    fi
    echo "$folder_id"
}

upsert_note() {
    local folder_id="$1"
    local note_name="$2"
    local note_content="$3"

    local existing_item=$(bw list items --search "$note_name" | jq -r ".[] | select(.type==2 and .name==\"$note_name\") | .id")
    local item_id

    if [[ -n "$existing_item" ]]; then
        status "Updating note '$note_name' in Bitwarden..."
        bw get item "$existing_item" | \
            jq --arg notes "$note_content" '.notes = $notes' | \
            bw encode | \
            bw edit item "$existing_item" > /dev/null
        if [[ $? -ne 0 ]]; then
            status "Failed to update note '$note_name' (ID: $existing_item) in Bitwarden."
            return 1
        fi
        item_id="$existing_item"
    else
        status "Creating note '$note_name' in Bitwarden..."
        local creation_output
        creation_output=$(bw get template item | \
            jq --arg name "$note_name" \
               --arg folder_id "$folder_id" \
               --arg notes "$note_content" \
            '.type = 2 | .secureNote.type = 0 | .name = $name | .folderId = $folder_id | .notes = $notes' | \
            bw encode | \
            bw create item)
        if [[ $? -ne 0 ]]; then
            status "Failed to execute 'bw create item' for '$note_name'."
            return 1
        fi
         item_id=$(echo "$creation_output" | jq -r '.id')
         if [[ -z "$item_id" || "$item_id" == "null" ]]; then
             status "Failed to create note '$note_name' in Bitwarden (ID not found)."
             return 1
         fi
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
    bw create attachment --file "$file_path" --itemid "$item_id" > /dev/null
    if [[ $? -ne 0 ]]; then
        status "Failed to add attachment '$file_path' to item ID '$item_id'."
        return 1
    fi
}