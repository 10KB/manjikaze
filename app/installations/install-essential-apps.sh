essential_apps=($(ls "$MANJIKAZE_DIR/app/installations/essential/"*.sh | xargs -n1 basename | sed 's/\.sh$//'))

echo "The following essential apps will be installed:"
printf "  - %s\n" "${essential_apps[@]}"

if ! gum confirm "Do you want to proceed with the installation?"; then
    status "Essential apps installation cancelled."
    return
fi

status "Installing essential apps..."
disable_sleep

# Install oh-my-zsh first
if [ -f "$MANJIKAZE_DIR/app/installations/essential/oh-my-zsh.sh" ]; then
    source "$MANJIKAZE_DIR/app/installations/essential/oh-my-zsh.sh"
fi

# Install remaining apps
for app in "${essential_apps[@]}"; do
    if [ "$app" != "oh-my-zsh" ]; then
        source "$MANJIKAZE_DIR/app/installations/essential/${app}.sh"
    fi
    if [ "$app" == "cursor" ]; then
        install_cursor
    fi
done

enable_sleep

status "A system reboot is recommended to ensure Docker functions correctly and user group changes take effect."
if gum confirm "Do you want to reboot the system now?"; then
    status "Rebooting system..."
    sudo reboot
else
    status "Reboot cancelled by user. Please remember to reboot your system soon for Docker to work correctly."
fi

status "Essential apps installation completed."
