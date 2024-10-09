#!/bin/bash

set -e

source ./utils/common.sh

prerequisites=(archlinux-keyring base-devel git gum)
to_install=()

for pkg in "${prerequisites[@]}"; do
    if ! is_installed "$pkg"; then
        to_install+=("$pkg")
    fi
done

if [ ${#to_install[@]} -ne 0 ]; then
    status "Installing prerequisites: ${to_install[*]}..."
    sudo pacman -Sy "${to_install[@]}" --noconfirm --noprogressbar --quiet
fi

source ./app/installations/update-installed-apps.sh
source ./app/installations/install-essential-apps.sh
source ./app/installations/install-recommended-apps.sh
source ./app/installations/install-optional-apps.sh
source ./app/installations/remove-preinstalled-apps.sh
source ./app/security/yubikey-setup-slot.sh
source ./app/security/yubikey-full-disk-encryption.sh
source ./app/security/yubikey-pam-authentication.sh
source ./app/security/yubikey-suspend.sh
source ./app/security/yubikey-replace.sh
source ./app/security/yubikey-bitwarden.sh
source ./app/security/audit-user-password.sh
source ./app/security/audit-luks-volume.sh
source ./app/configuration/configure-font.sh
source ./app/configuration/configure-git.sh
source ./app/configuration/configure-gnome.sh
source ./app/configuration/configure-nautilus.sh

declare -A menu
menu=(
    ["1:App installation"]="install_apps_menu"
    ["2:Security"]="security_menu"
    ["3:Configuration"]="configuration_menu"
)

declare -A install_apps_menu
install_apps_menu=(
    ["1:Essential apps"]="install_essential_apps"
    ["2:Recommended apps"]="install_recommended_apps"
    ["3:Optional apps"]="install_optional_apps"
    ["4:Update installed apps"]="update_installed_apps"
    ["5:Remove preinstalled apps"]="remove_preinstalled_apps"
)

declare -A security_menu
security_menu=(
    ["1:Yubikey setup"]="yubikey_setup_menu"
    ["2:Audit"]="audit_menu"
    ["3:Bitwarden"]="bitwarden_menu"
)

declare -A yubikey_setup_menu
yubikey_setup_menu=(
    ["1:Setup Yubikey slot"]="yubikey_setup_slot"
    ["2:Setup Yubikey for full disk encryption"]="yubikey_full_disk_encryption"
    ["3:Setup Yubikey for PAM authentication"]="yubikey_pam_authentication"
    ["4:Setup YubiKey suspend"]="yubikey_suspend"
    ["5:Setup Yubikey for Bitwarden"]="yubikey_bitwarden"
    ["6:Replace faulty YubiKey"]="yubikey_replace"
)

declare -A audit_menu
audit_menu=(
    ["1:Audit user password strength"]="audit_user_password"
    ["2:Audit full disk encryption"]="audit_luks_volume"
)

declare -A bitwarden_menu
bitwarden_menu=(
    ["1:Pull SSH and GPG keys"]="bitwarden_pull_ssh_gpg_keys"
    ["2:Push SSH keys"]="bitwarden_push_ssh_keys"
    ["3:Pull AWS profiles"]="bitwarden_pull_aws_profiles"
)

declare -A configuration_menu
configuration_menu=(
    ["1:GNOME"]="configure_gnome"
    ["2:Nautilus file manager"]="configure_nautilus"
    ["3:Monospace font"]="configure_font"
    ["4:Git"]="configure_git"
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

handle_menu menu "Main Menu"