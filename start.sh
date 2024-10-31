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
source ./app/security/yubikey/yubikey-setup-slot.sh
source ./app/security/yubikey/yubikey-full-disk-encryption.sh
source ./app/security/yubikey/yubikey-pam-authentication.sh
source ./app/security/yubikey/yubikey-suspend.sh
source ./app/security/yubikey/yubikey-replace.sh
source ./app/security/yubikey/yubikey-bitwarden.sh
source ./app/security/yubikey/yubikey-setup-gpg.sh
source ./app/security/audit/audit-user-password.sh
source ./app/security/audit/audit-luks-volume.sh
source ./app/security/bitwarden/bitwarden-pull-ssh-gpg-keys.sh
source ./app/security/bitwarden/bitwarden-push-ssh-gpg-keys.sh
source ./app/security/ssh/generate-ssh-key.sh
source ./app/security/ssh/generate-gpg-key.sh
source ./app/security/ssh/configure-git-gpg.sh
source ./app/security/ssh/enable-ssh-agent.sh
source ./app/configuration/configure-font.sh
source ./app/configuration/configure-git.sh
source ./app/configuration/configure-gnome.sh
source ./app/configuration/configure-nautilus.sh

declare -A menu
menu=(
    ["1:App installation"]="install_apps_menu"
    ["2:Configuration"]="configuration_menu"
    ["3:Security"]="security_menu"
)

declare -A install_apps_menu
install_apps_menu=(
    ["1:Essential apps"]="install_essential_apps"
    ["2:Recommended apps"]="install_recommended_apps"
    ["3:Optional apps"]="install_optional_apps"
    ["4:Update installed apps"]="update_installed_apps"
    ["5:Remove preinstalled apps"]="remove_preinstalled_apps"
)


declare -A configuration_menu
configuration_menu=(
    ["1:GNOME"]="configure_gnome"
    ["2:Nautilus file manager"]="configure_nautilus"
    ["3:Monospace font"]="configure_font"
    ["4:Git"]="configure_git"
)

declare -A security_menu
security_menu=(
    ["1:Bitwarden"]="bitwarden_menu"
    ["2:SSH and GPG"]="ssh_gpg_menu"
    ["3:Yubikey"]="yubikey_menu"
    ["4:Audit"]="audit_menu"
)

declare -A bitwarden_menu
bitwarden_menu=(
    ["1:Pull SSH and GPG keys"]="bitwarden_pull_ssh_gpg_keys"
    ["2:Push SSH and GPG keys"]="bitwarden_push_ssh_gpg_keys"
    ["3:Pull AWS profiles"]="bitwarden_pull_aws_profiles"
)

declare -A ssh_gpg_menu
ssh_gpg_menu=(
    ["1:Generate SSH key"]="generate_ssh_key"
    ["2:Generate GPG key"]="generate_gpg_key"
    ["3:Configure Git GPG"]="configure_git_gpg"
    ["4:Enable SSH agent"]="enable_ssh_agent"
)

declare -A yubikey_menu
yubikey_menu=(
    ["1:Setup disk encryption slot"]="yubikey_setup_slot"
    ["2:Setup disk encryption MFA"]="yubikey_full_disk_encryption"
    ["3:Setup PAM authentication"]="yubikey_pam_authentication"
    ["4:Setup suspend"]="yubikey_suspend"
    ["5:Setup Bitwarden MFA"]="yubikey_bitwarden"
    ["6:Setup GPG"]="yubikey_setup_gpg"
    ["7:Replace faulty YubiKey"]="yubikey_replace"
)

declare -A audit_menu
audit_menu=(
    ["1:Audit user password strength"]="audit_user_password"
    ["2:Audit full disk encryption"]="audit_luks_volume"
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