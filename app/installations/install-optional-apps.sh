install_optional_apps() {
    OPTIONAL_APPS=("Brave" "Dropbox" "Filezilla" "GitKraken" "Kubectl" "Libreoffice" "Signal" "Smartgit" "Spotify" "Todoist" "VLC")
    DEFAULT_OPTIONAL_APPS='Dropbox,Signal,Smartgit,Spotify'

    SELECTED_OPTIONAL_APPS=$(gum choose "${OPTIONAL_APPS[@]}" --no-limit --selected $DEFAULT_OPTIONAL_APPS --height 10 --header "Select optional apps" | tr ' ' '-')

    if [ -z "$SELECTED_OPTIONAL_APPS" ]; then
        status "No optional apps selected. Skipping installation."
        return
    fi

    echo "The following optional apps will be installed:"
    printf "  - %s\n" ${SELECTED_OPTIONAL_APPS//-/ }

    if ! gum confirm "Do you want to proceed with the installation?"; then
        status "Optional apps installation cancelled."
        return
    fi

    status "Installing optional apps..."

    for app in ${SELECTED_OPTIONAL_APPS//-/ }; do
        app_file="app/installations/optional/${app,,}.sh"
        if [ -f "$app_file" ]; then
            source "$app_file"
        else
            status "Installation script for $app not found. Skipping."
        fi
    done

    status "Optional apps installation completed."
}