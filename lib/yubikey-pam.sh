#!/bin/bash

# Unlock, sudo and polkit with a YubiKey through pam_u2f: its FIDO2 PIN plus a touch.
# The password keeps working as a fallback. Slot 2 (challenge-response) stays for disk encryption.

# Only root can change this file, so a user or malware can't add a key of their own.
YUBIKEY_PAM_AUTHFILE="/etc/u2f_mappings"
# A fixed relying party ID keeps registrations valid when the hostname changes.
YUBIKEY_PAM_ORIGIN="pam://manjikaze"
YUBIKEY_PAM_LINE="auth sufficient pam_u2f.so authfile=$YUBIKEY_PAM_AUTHFILE origin=$YUBIKEY_PAM_ORIGIN cue pinverification=1 userverification=0"
# Where the earlier touch-only setup (pam_yubico) added itself.
YUBIKEY_PAM_LEGACY_FILES=(/etc/pam.d/sudo /etc/pam.d/system-auth /etc/pam.d/login /etc/pam.d/polkit-1 /etc/pam.d/gnome-keyring)
YUBIKEY_INSERT_ACTION="/usr/local/bin/yubikey-insert-action.sh"
YUBIKEY_ACTION_RULES="/etc/udev/rules.d/90-yubikey-actions.rules"

yubikey_pam_backup() {
    if [[ -n "$YUBIKEY_PAM_BACKUP" ]]; then
        return 0
    fi
    YUBIKEY_PAM_BACKUP="/etc/pam.d.backup-$(date +%Y%m%d%H%M%S)"
    sudo cp -a /etc/pam.d "$YUBIKEY_PAM_BACKUP" || return 1
    status "Backed up /etc/pam.d to $YUBIKEY_PAM_BACKUP."
}

yubikey_pam_ensure_pin() {
    local info
    if ! info=$(ykman fido info 2>/dev/null); then
        status "No YubiKey found. Insert your YubiKey and try again."
        return 1
    fi
    if grep -qE '^PIN:[[:space:]]+Not set' <<< "$info"; then
        status "Your YubiKey has no FIDO2 PIN yet. Choose one; you will type it to unlock."
        ykman fido access change-pin || return 1
    fi
}

# Registers the inserted YubiKey for the current user. With "replace", earlier keys stop working.
yubikey_pam_register() {
    local user credential
    user=$(id -un)
    if [[ "$1" != "replace" ]] && grep -qs "^$user:" "$YUBIKEY_PAM_AUTHFILE"; then
        if ! gum confirm "A YubiKey is already registered for $user. Also register the inserted YubiKey, for example a spare?"; then
            return 0
        fi
    fi

    status "Enter the PIN of your YubiKey, then touch it when it flashes..."
    credential=$(pamu2fcfg -n -N -o "$YUBIKEY_PAM_ORIGIN") || return 1
    if [[ "$credential" != :* ]]; then
        status "pamu2fcfg returned no registration."
        return 1
    fi

    sudo touch "$YUBIKEY_PAM_AUTHFILE" || return 1
    # hyprlock runs as the user and has to read it.
    sudo chmod 644 "$YUBIKEY_PAM_AUTHFILE" || return 1
    if [[ "$1" == "replace" ]]; then
        sudo sed -i "/^$user:/d" "$YUBIKEY_PAM_AUTHFILE" || return 1
    fi
    if grep -qs "^$user:" "$YUBIKEY_PAM_AUTHFILE"; then
        sudo sed -i "/^$user:/ s|\$|$credential|" "$YUBIKEY_PAM_AUTHFILE" || return 1
    else
        echo "$user$credential" | sudo tee -a "$YUBIKEY_PAM_AUTHFILE" > /dev/null || return 1
    fi
    status "YubiKey registered for $user."
}

# One line in system-auth: sudo, polkit-1, login, gdm-password and hyprlock all include it.
yubikey_pam_enable() {
    yubikey_pam_backup || return 1
    if grep -q "pam_u2f.so" /etc/pam.d/system-auth; then
        sudo sed -i "s|^.*pam_u2f\.so.*\$|$YUBIKEY_PAM_LINE|" /etc/pam.d/system-auth || return 1
    else
        sudo sed -i "1i$YUBIKEY_PAM_LINE" /etc/pam.d/system-auth || return 1
    fi
}

# Pass "replace" to drop the keys registered so far, for example after losing one.
yubikey_pam_configure() {
    install_package "pam-u2f" repo || return 1
    yubikey_pam_ensure_pin || return 1
    yubikey_pam_register "$1" || return 1
    yubikey_pam_enable || return 1
    status "Unlock, sudo and polkit now accept your YubiKey with its PIN. Your password keeps working."
}

yubikey_pam_legacy_present() {
    grep -qs "pam_yubico.so" "${YUBIKEY_PAM_LEGACY_FILES[@]}" || [[ -f "$YUBIKEY_INSERT_ACTION" ]]
}

# Removes touch-only unlock: the pam_yubico lines and unlocking on insertion.
yubikey_pam_remove_legacy() {
    local file
    for file in "${YUBIKEY_PAM_LEGACY_FILES[@]}"; do
        if grep -qs "pam_yubico.so" "$file"; then
            yubikey_pam_backup || return 1
            sudo sed -i '/pam_yubico\.so/d' "$file" || return 1
        fi
    done
    if grep -qs "pam_echo.so Please touch your yubikey" /etc/pam.d/sudo; then
        sudo sed -i '/pam_echo\.so Please touch your yubikey/d' /etc/pam.d/sudo || return 1
    fi
    # Only that pam_echo prompt needed it; sudo shows the cue of pam_u2f anyway.
    sudo rm -f /etc/sudoers.d/99-yubikey-prompt || return 1

    if [[ -f "$YUBIKEY_INSERT_ACTION" ]]; then
        if [[ -f "$YUBIKEY_ACTION_RULES" ]]; then
            sudo sed -i '/[Ii]nsert/d' "$YUBIKEY_ACTION_RULES" || return 1
        fi
        sudo rm -f "$YUBIKEY_INSERT_ACTION" || return 1
        sudo udevadm control --reload-rules
    fi
}
