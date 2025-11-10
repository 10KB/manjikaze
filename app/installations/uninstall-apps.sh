OPTIONAL_APPS=($(ls "$MANJIKAZE_DIR/app/installations/optional/"*.sh | xargs -n1 basename | sed 's/\.sh$//'))
ESSENTIAL_APPS=($(ls "$MANJIKAZE_DIR/app/installations/essential/"*.sh | xargs -n1 basename | sed 's/\.sh$//'))
RECOMMENDED_APPS=($(ls "$MANJIKAZE_DIR/app/installations/recommended/"*.sh | xargs -n1 basename | sed 's/\.sh$//'))
ALL_APPS=($(printf '%s\n' "${ESSENTIAL_APPS[@]}" "${RECOMMENDED_APPS[@]}" "${OPTIONAL_APPS[@]}" | sort))

SELECTED_APPS=$(gum choose "${ALL_APPS[@]}" --no-limit --height 20 --header "Select apps to uninstall" | tr ' ' '+')

if [ -z "$SELECTED_APPS" ]; then
    status "No apps to uninstall selected. Skipping uninstallation."
    return
fi

echo "The following apps will be uninstalled:"
printf "  - %s\n" ${SELECTED_APPS//+/ }

if ! gum confirm "Do you want to proceed with the uninstallation?"; then
    status "Apps uninstallation cancelled."
    return
fi

status "Uninstalling apps..."
disable_sleep

for app in ${SELECTED_APPS//+/ }; do
    script_found=false
    for dir in essential recommended optional; do
        script="$MANJIKAZE_DIR/app/installations/$dir/${app}.sh"
        if [ -f "$script" ]; then
            source "$script"
            uninstall
            script_found=true
            break
        fi
    done
    
    if [ "$script_found" = false ]; then
        status "Uninstall script for $app not found. Can't uninstall."
    fi
done

enable_sleep
status "Apps uninstallation completed."
