#!/bin/bash

# Dynamic module loading
load_module() {
    local module=$1
    source "$MANJIKAZE_DIR/app/$module"
}

# Menu definitions
declare -A menu=(
    ["1:🔧 Setup"]="setup_menu"
    ["2:⚙️  Configuration"]="configuration_menu"
    ["3:🔒 Security"]="security_menu"
    # ["4:📦 Applications"]="applications_menu"
    # ["5:🔍 System"]="system_menu"
)

declare -A setup_menu
setup_menu=(
    ["1:Install essential apps"]="load_module installations/install-essential-apps.sh"
    ["2:Install recommended apps"]="load_module installations/install-recommended-apps.sh"
    ["3:Choose optional apps"]="load_module installations/install-optional-apps.sh"
    ["4:Update installed apps"]="load_module installations/update-installed-apps.sh"
    ["5:Uninstall apps"]="load_module installations/uninstall-apps.sh"
    ["6:Rebuild installed apps"]="load_module installations/rebuild-installed-apps.sh"
    ["7:Remove preinstalled apps"]="load_module installations/remove-preinstalled-apps.sh"
)

declare -A configuration_menu=(
    ["1:GNOME desktop"]="load_module configuration/configure-gnome.sh"
    ["2:Nautilus file manager"]="load_module configuration/configure-nautilus.sh"
    ["3:Monospace font"]="load_module configuration/configure-font.sh"
    ["4:Git"]="load_module configuration/configure-git.sh"
    ["5:Network printer discovery"]="load_module configuration/configure-printing.sh"
)

declare -A security_menu=(
    ["1:Generate Yubikey secret for disk encryption"]="load_module security/yubikey/yubikey-setup-slot.sh"
    ["2:Configure Yubikey as MFA for disk encryption"]="load_module security/yubikey/yubikey-full-disk-encryption.sh"
    ["3:Configure Yubikey as MFA for system"]="load_module security/yubikey/yubikey-pam-authentication.sh"
    ["4:Auto lock on Yubikey removal"]="load_module security/yubikey/yubikey-suspend.sh"
    ["5:Replace faulty YubiKey"]="load_module security/yubikey/yubikey-replace.sh"
    ["6:Configure weekly update checks"]="load_module security/updates/configure-update-checker.sh"
)

handle_menu() {
    local -n menu_ref=$1
    local menu_name=$2
    local header="${menu_name:-Main Menu}"

    while true; do
        readarray -t sorted_keys < <(printf '%s\n' "${!menu_ref[@]}" | sort)

        local options=()
        for key in "${sorted_keys[@]}"; do
            options+=("${key#*:}")  # Remove the number prefix
        done
        options+=("Back")

        CHOICE=$(gum choose "${options[@]}" --header "$header")

        if [[ "$CHOICE" == "Back" ]]; then
            return
        else
            for key in "${sorted_keys[@]}"; do
                if [[ "${key#*:}" == "$CHOICE" ]]; then
                    local action=${menu_ref[$key]}
                    if [[ "$action" == *"_menu" ]]; then
                        handle_menu "$action" "$CHOICE"
                    else
                        $action
                        echo "Press Enter to continue..."
                        read
                    fi
                    break
                fi
            done
        fi
    done
}
