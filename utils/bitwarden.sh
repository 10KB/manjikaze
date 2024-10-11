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