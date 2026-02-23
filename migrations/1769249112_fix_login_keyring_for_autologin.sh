#!/bin/bash
set -e

# Replace the encrypted login keyring with a password-less version for auto-login setups.
#
# The previous migration (1769249111) created a password-less Default_keyring and set it
# as the default. However, many apps (Slack, Chrome, etc.) still have their credentials
# stored in the old encrypted "login" keyring. When those apps try to access the login
# keyring, GNOME can't unlock it without a password (since auto-login provides none),
# resulting in a password prompt.
#
# This migration removes the encrypted login.keyring and replaces it with a password-less
# version. Apps will need to re-authenticate once, but after that they'll store credentials
# in the unlocked keyring without prompts.

KEYRING_DIR="$HOME/.local/share/keyrings"
LOGIN_KEYRING="$KEYRING_DIR/login.keyring"

# Only apply if using auto-login (check GDM config)
if ! grep -q "AutomaticLoginEnable=true\|AutomaticLoginEnable=True" /etc/gdm/custom.conf 2>/dev/null; then
    status "Auto-login is not enabled, skipping login keyring fix."
    return 0
fi

# Check if login.keyring exists and is in the old encrypted binary format
if [[ ! -f "$LOGIN_KEYRING" ]]; then
    status "No login.keyring found, skipping."
    return 0
fi

# If the login keyring is already a plaintext (password-less) keyring, skip
if head -1 "$LOGIN_KEYRING" 2>/dev/null | grep -q "^\[keyring\]"; then
    status "Login keyring is already password-less, skipping."
    return 0
fi

status "Replacing encrypted login keyring with password-less version..."

# Backup the old encrypted login keyring
cp "$LOGIN_KEYRING" "$LOGIN_KEYRING.backup-$(date +%s)"
status "Backed up existing login.keyring"

# Create a new password-less login keyring
cat << EOF > "$LOGIN_KEYRING"
[keyring]
display-name=Login
ctime=$(date +%s)
mtime=0
lock-on-idle=false
lock-after=false
EOF

chmod 600 "$LOGIN_KEYRING"

# Also set the default keyring to "login" (this is what GNOME expects for auto-unlock)
echo "login" > "$KEYRING_DIR/default"
chmod 644 "$KEYRING_DIR/default"

status "Login keyring replaced with password-less version."
status "Apps that stored credentials in the old keyring (Slack, Chrome, etc.) will need"
status "to re-authenticate once. After that, no more password prompts!"
status "Please reboot for changes to take full effect."
