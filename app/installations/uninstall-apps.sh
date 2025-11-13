OPTIONAL_APPS=($(ls "$MANJIKAZE_DIR/app/installations/optional/"*.sh | xargs -n1 basename | sed 's/\.sh$//'))
ESSENTIAL_APPS=($(ls "$MANJIKAZE_DIR/app/installations/essential/"*.sh | xargs -n1 basename | sed 's/\.sh$//'))
ALL_APPS=("${OPTIONAL_APPS[@]}" "${ESSENTIAL_APPS[@]}")

SELECTED_APPS=$(gum choose "${ALL_APPS[@]}" --no-limit --height 20 --header "Select apps to uninstall" | tr ' ' '-')

if [ -z "$SELECTED_APPS" ]; then
    status "No apps to uninstall selected. Skipping uninstallation."
    return
fi

echo "The following apps will be uninstalled:"
printf "  - %s\n" ${SELECTED_APPS//-/ }

if ! gum confirm "Do you want to proceed with the uninstallation?"; then
    status "Apps uninstallation cancelled."
    return
fi

status "Uninstalling apps..."
disable_sleep

for app in "${SELECTED_APPS[@]}"; do
    uninstall_package "$app" aur
done

enable_sleep
status "Apps uninstallation completed."
