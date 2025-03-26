#!/bin/bash

# Dynamic module loading
load_module() {
    local module=$1
    source "$MANJIKAZE_DIR/app/$module"
}

# Menu definitions
declare -A menu=(
    ["1:🔧 Setup"]="setup_menu"
    ["2:⚙️ Configuration"]="configuration_menu"
    ["3:🔒 Security"]="security_menu"
    ["4:📦 Applications"]="applications_menu"
    ["5:🔍 System"]="system_menu"
)


declare -A setup_menu
setup_menu=(
    ["1:Essential apps"]="load_module installations/install-essential-apps.sh"
    ["2:Recommended apps"]="load_module installations/install-recommended-apps.sh"
    ["3:Optional apps"]="load_module installations/install-optional-apps.sh"
    ["4:Update installed apps"]="load_module installations/update-installed-apps.sh"
    ["5:Remove preinstalled apps"]="load_module installations/remove-preinstalled-apps.sh"
)

declare -A configuration_menu=(
    ["1:GNOME desktop"]="load_module configuration/gnome.sh"
    ["2:File manager"]="load_module configuration/nautilus.sh"
    ["3:Terminal"]="load_module configuration/terminal.sh"
    ["4:Git"]="load_module configuration/git.sh"
    ["5:Printing"]="load_module configuration/printing.sh"
)

handle_menu() {
    local -n menu_ref=$1
    local menu_name=$2
    local header="${menu_name:-Main Menu}"

    while true; {
        clear
        gum style \
            --border normal \
            --align left \
            --width 50 \
            --margin "1 2" \
            "$header"

        readarray -t sorted_keys < <(printf '%s\n' "${!menu_ref[@]}" | sort)
        
        local options=()
        for key in "${sorted_keys[@]}"; do
            options+=("${key#*:}")
        done
        options+=("↩️  Back")

        CHOICE=$(gum choose "${options[@]}")

        if [[ "$CHOICE" == "↩️  Back" ]]; then
            return
        else
            for key in "${sorted_keys[@]}"; do
                if [[ "${key#*:}" == "$CHOICE" ]]; then
                    local action=${menu_ref[$key]}
                    if [[ "$action" == *"_menu" ]]; then
                        handle_menu "$action" "$CHOICE"
                    else
                        eval "$action"
                        gum confirm "Press enter to continue..." || true
                    fi
                    break
                fi
            done
        fi
    }
}