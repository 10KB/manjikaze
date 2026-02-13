#!/bin/bash
set -e

# Create a password-less default keyring for auto-login setups
# This prevents the keyring unlock prompt after automatic GNOME login

KEYRING_DIR="$HOME/.local/share/keyrings"
KEYRING_FILE="$KEYRING_DIR/Default_keyring.keyring"
DEFAULT_FILE="$KEYRING_DIR/default"

# Only apply if using auto-login (check GDM config)
if ! grep -q "AutomaticLoginEnable=true\|AutomaticLoginEnable=True" /etc/gdm/custom.conf 2>/dev/null; then
    status "Auto-login is not enabled, skipping keyring configuration."
    return 0
fi

# Check if keyring already exists and is configured correctly
if [[ -f "$KEYRING_FILE" ]] && grep -q "lock-on-idle=false" "$KEYRING_FILE" 2>/dev/null; then
    status "Default keyring is already configured, skipping."
    return 0
fi

status "Configuring password-less default keyring for auto-login..."

# Backup existing keyring if present
if [[ -f "$KEYRING_FILE" ]]; then
    status "Backing up existing keyring..."
    cp "$KEYRING_FILE" "$KEYRING_FILE.backup-$(date +%s)"
fi

mkdir -p "$KEYRING_DIR"

cat << EOF > "$KEYRING_FILE"
[keyring]
display-name=Default keyring
ctime=$(date +%s)
mtime=0
lock-on-idle=false
lock-after=false
EOF

echo "Default_keyring" > "$DEFAULT_FILE"

chmod 700 "$KEYRING_DIR"
chmod 600 "$KEYRING_FILE"
chmod 644 "$DEFAULT_FILE"

status "Default keyring configured successfully."
status "Note: You may need to log out and back in for this to take effect."
