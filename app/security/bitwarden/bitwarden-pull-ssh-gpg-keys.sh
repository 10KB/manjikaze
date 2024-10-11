source ./utils/bitwarden.sh

bitwarden_pull_ssh_gpg_keys() {
    if ! unlock_bitwarden; then
        return 1
    fi

    local ssh_dir="$HOME/.ssh"
    local folder_name="SSH"

    mkdir -p "$ssh_dir"

    local folder_id=$(bw list folders | jq -r ".[] | select(.name==\"$folder_name\") | .id")
    if [[ -z "$folder_id" ]]; then
        status "SSH folder not found in Bitwarden."
        return 1
    fi

    local items=$(bw list items --folderid "$folder_id")

    echo "$items" | jq -c '.[]' | while read -r item; do
        local item_id=$(echo "$item" | jq -r '.id')
        local item_name=$(echo "$item" | jq -r '.name')
        
        status "Processing $item_name..."

        local attachment_id=$(echo "$item" | jq -r '.attachments[0].id')
        
        if [[ -n "$attachment_id" ]]; then
            if bw get attachment "$attachment_id" --itemid "$item_id" --output "$ssh_dir/$item_name" > /dev/null; then
                status "Successfully downloaded $item_name"
                chmod 600 "$ssh_dir/$item_name"
            else
                status "Failed to download $item_name"
            fi
        else
            status "No attachment found for $item_name"
        fi
    done

    status "All SSH keys have been pulled from Bitwarden."
}
