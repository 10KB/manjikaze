OPTIONAL_APPS=($(ls "$MANJIKAZE_DIR/app/installations/optional/"*.sh | xargs -n1 basename | sed 's/\.sh$//'))

SELECTED_OPTIONAL_APPS=$(gum choose "${OPTIONAL_APPS[@]}" --no-limit --height 20 --header "Select optional apps" | tr ' ' '-')

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
disable_sleep

for app in ${SELECTED_OPTIONAL_APPS//-/ }; do
    app_file="$MANJIKAZE_DIR/app/installations/optional/${app,,}.sh"
    if [ -f "$app_file" ]; then
        source "$app_file"
    else
        status "Installation script for $app not found. Skipping."
    fi
done

enable_sleep
status "Optional apps installation completed."
