install_essential_apps() {
    essential_apps=($(ls app/installations/essential/*.sh | xargs -n1 basename | sed 's/\.sh$//'))

    echo "The following essential apps will be installed:"
    printf "  - %s\n" "${essential_apps[@]}"

    if ! gum confirm "Do you want to proceed with the installation?"; then
        status "Essential apps installation cancelled."
        return
    fi

    status "Installing essential apps..."

    # Install yay first
    source "app/installations/essential/yay.sh"

    for app in "${essential_apps[@]}"; do
        if [ "$app" != "yay" ]; then
            source "app/installations/essential/${app}.sh"
        fi
    done

    status "Essential apps installation completed."
}