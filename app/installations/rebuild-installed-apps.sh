get_apps_with_rebuild() {
    local dir="$1"
    local apps=()
    
    for script in "$MANJIKAZE_DIR/app/installations/$dir/"*.sh; do
        if [ -f "$script" ] && grep -q "^rebuild()" "$script"; then
            apps+=("$(basename "$script" .sh)")
        fi
    done
    
    printf '%s\n' "${apps[@]}"
}

OPTIONAL_APPS=($(get_apps_with_rebuild "optional"))
ESSENTIAL_APPS=($(get_apps_with_rebuild "essential"))
RECOMMENDED_APPS=($(get_apps_with_rebuild "recommended"))
ALL_APPS=($(printf '%s\n' "${ESSENTIAL_APPS[@]}" "${RECOMMENDED_APPS[@]}" "${OPTIONAL_APPS[@]}" | sort))

if [ ${#ALL_APPS[@]} -eq 0 ]; then
    status "No apps with rebuild support found."
    return
fi

SELECTED_APPS=$(gum choose "${ALL_APPS[@]}" --no-limit --height 20 --header "Select apps to rebuild" | tr ' ' '+')

if [ -z "$SELECTED_APPS" ]; then
    status "No apps to rebuild selected. Skipping rebuild."
    return
fi

echo "The following apps will be rebuilt:"
printf "  - %s\n" ${SELECTED_APPS//+/ }

if ! gum confirm "Do you want to proceed with the rebuild?"; then
    status "Apps rebuild cancelled."
    return
fi

status "Rebuilding apps..."
disable_sleep

for app in ${SELECTED_APPS//+/ }; do
    script_found=false
    for dir in essential recommended optional; do
        script="$MANJIKAZE_DIR/app/installations/$dir/${app}.sh"
        if [ -f "$script" ]; then
            source "$script"
            rebuild
            script_found=true
            break
        fi
    done
    
    if [ "$script_found" = false ]; then
        status "Rebuild script for $app not found. Can't rebuild."
    fi
done

enable_sleep
status "Apps rebuild completed."
