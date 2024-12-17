hyprland_menu() {
    HYPRLAND_APPS=("Dolphin" "Grim" "Hyprland" "Hyprlock" "Hyprpaper" "Hyprpicker" "Kitty" "Slurp" "Vim" "Waybar" "Wofi")
    DEFAULT_HYPRLAND_APPS='Dolphin,Grim,Hyprland,Hyprlock,Hyprpaper,Kitty,Waybar,Wofi'

    SELECTED_HYPRLAND_APPS=$(gum choose "${HYPRLAND_APPS[@]}" --no-limit --selected $DEFAULT_HYPRLAND_APPS --height 15 --header "Select Hyprland apps" | tr ' ' '-')

    if [ -z "$SELECTED_HYPRLAND_APPS" ]; then
        status "No Hyprland apps selected. Skipping installation."
        return
    fi

    echo "The following Hyprland apps will be installed:"
    printf "  - %s\n" ${SELECTED_HYPRLAND_APPS//-/ }

    if ! gum confirm "Do you want to proceed with the installation?"; then
        status "Hyprland apps installation cancelled."
        return
    fi

    status "Installing Hyprland apps..."

    for app in ${SELECTED_HYPRLAND_APPS//-/ }; do
        app_file="app/installations/hyprland/${app,,}.sh"
        if [ -f "$app_file" ]; then
            source "$app_file"
        else
            status "Installation script for $app not found. Skipping."
        fi
    done

    status "Hyprland apps installation completed."
}