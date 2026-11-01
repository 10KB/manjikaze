#!/bin/bash
set -e

# Unlock, sudo and polkit with a YubiKey ask for its FIDO2 PIN instead of a touch alone,
# and inserting the YubiKey no longer unlocks the session.

source "$MANJIKAZE_DIR/lib/yubikey-pam.sh"

if ! yubikey_pam_legacy_present; then
    status "Touch-only YubiKey unlock is not configured, skipping."
    return 0
fi

if grep -qs "pam_yubico.so" "${YUBIKEY_PAM_LEGACY_FILES[@]}"; then
    status "A touch of your YubiKey alone unlocks this computer. From now on it also asks for the YubiKey's PIN."
    if gum confirm "Set up unlocking with your YubiKey and its PIN now? Insert your YubiKey first. If you skip this, you unlock with your password."; then
        yubikey_pam_configure || status "YubiKey unlock with PIN is not set up. Use your password, or try again via Security → Configure Yubikey as MFA for system."
    fi
fi

yubikey_pam_remove_legacy || return 1
status "Touch-only YubiKey unlock is removed."
