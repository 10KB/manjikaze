source ./lib/bitwarden.sh
    
bitwarden_push_ssh_gpg_keys() {
    if ! unlock_bitwarden; then
        return 1
    fi

    local ssh_dir="$HOME/.ssh"
    local folder_name="SSH"

    local folder_id=$(bw list folders | jq -r ".[] | select(.name==\"$folder_name\") | .id")
    if [[ -z "$folder_id" ]]; then
        status "Creating SSH folder in Bitwarden..."
        folder_id=$(bw get template folder | jq --arg name "$folder_name" '.name=$name' | bw encode | bw create folder | jq -r '.id')
        if [[ -z "$folder_id" ]]; then
            status "Failed to create SSH folder in Bitwarden."
            return 1
        fi
    fi

    for key_file in "$ssh_dir"/id_*; do
        if [[ -f "$key_file" && ! "$key_file" =~ \.pub$ ]]; then
            local key_name=$(basename "$key_file")
            status "Processing $key_name..."

            local existing_item=$(bw list items --search "$key_name" | jq -r ".[] | select(.type==2 and .name==\"$key_name\") | .id")

            if [[ -n "$existing_item" ]]; then
                status "Updating existing note for $key_name..."
                bw get item "$existing_item" | jq ".notes = \"SSH key stored as attachment\"" | bw encode | bw edit item "$existing_item" > /dev/null
                bw create attachment --file "$key_file" --itemid "$existing_item" > /dev/null
            else
                status "Creating new note for $key_name..."
                local item_id=$(bw get template item | jq --arg name "$key_name" --arg folder_id "$folder_id" \
                    '.type = 2 | .secureNote.type = 0 | .name = $name | .folderId = $folder_id | .notes = "SSH key stored as attachment"' | \
                    bw encode | bw create item | jq -r '.id')
                
                if [[ -n "$item_id" ]]; then
                    bw create attachment --file "$key_file" --itemid "$item_id" > /dev/null
                else
                    status "Failed to create note for $key_name"
                    continue
                fi
            fi

            status "Successfully processed $key_name"
        fi
    done

    status "All SSH keys have been pushed to Bitwarden."
}
