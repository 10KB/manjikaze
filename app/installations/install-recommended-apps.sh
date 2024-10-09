install_recommended_apps() {
    status "Installing recommended apps..."

    recommended_apps=($(ls app/installations/recommended/*.sh | xargs -n1 basename | sed 's/\.sh$//'))

    echo "The following recommended apps will be installed:"
    printf "  - %s\n" "${recommended_apps[@]}"

    if ! gum confirm "Do you want to proceed with the installation?"; then
        status "Recommended apps installation cancelled."
        return
    fi

    status "Installing recommended apps..."

    for app in "${recommended_apps[@]}"; do
        source "app/installations/recommended/${app}.sh"
    done

    status "Recommended apps installation completed."
}