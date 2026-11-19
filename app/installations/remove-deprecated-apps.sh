DEPRECATED_DIR="$MANJIKAZE_DIR/app/installations/deprecated"

INSTALLED_DEPRECATED=()
for script in "$DEPRECATED_DIR"/*.sh; do
    [ -f "$script" ] || continue
    (
        source "$script"
        installed
    ) && INSTALLED_DEPRECATED+=("$(basename "$script" .sh)")
done

if [ ${#INSTALLED_DEPRECATED[@]} -eq 0 ]; then
    status "No deprecated apps are installed."
    return
fi

SELECTED_APPS=$(gum choose "${INSTALLED_DEPRECATED[@]}" --no-limit --height 20 \
    --selected "$(IFS=,; echo "${INSTALLED_DEPRECATED[*]}")" \
    --header "Select deprecated apps to remove")

if [ -z "$SELECTED_APPS" ]; then
    status "No deprecated apps selected. Skipping removal."
    return
fi

echo "The following deprecated apps will be removed:"
printf "  - %s\n" $SELECTED_APPS

if ! gum confirm "Do you want to proceed with the removal?"; then
    status "Deprecated apps removal cancelled."
    return
fi

status "Removing deprecated apps..."
disable_sleep

for app in $SELECTED_APPS; do
    source "$DEPRECATED_DIR/${app}.sh"
    uninstall
done

enable_sleep
status "Deprecated apps removal completed."
