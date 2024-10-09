remove_preinstalled_apps() {
    apps=(
        "gnome-contacts"
        "gnome-chess"
        "gnome-mines"
        "gnome-maps"
        "gnome-tour"
        "gnome-weather"
        "endeavour"
        "fragments"
        "totem"
        "malcontent"
        "quadrapassel"
        "iagno"
        "lollypop"
    )

    echo "The following preinstalled apps will be removed:"
    printf "  - %s\n" "${apps[@]}"

    if ! gum confirm "Do you want to proceed with the removal?"; then
        status "Preinstalled apps removal cancelled."
        return
    fi

    status "Removing preinstalled apps..."

    for app in "${apps[@]}"; do
        if pacman -Qi "$app" &> /dev/null; then
            sudo pacman -R "$app" --noconfirm --noprogressbar --quiet
        fi
    done

    status "Preinstalled apps removal completed."
}