essential_apps=($(ls "$MANJIKAZE_DIR/app/installations/essential/"*.sh | xargs -n1 basename | sed 's/\.sh$//'))

echo "The following essential apps will be installed:"
printf "  - %s\n" "${essential_apps[@]}"

if ! gum confirm "Do you want to proceed with the installation?"; then
    status "Essential apps installation cancelled."
    return
fi

status "Installing essential apps..."
disable_sleep

for app in "${essential_apps[@]}"; do
    source "$MANJIKAZE_DIR/app/installations/essential/${app}.sh"
done

enable_sleep
status "Essential apps installation completed."
