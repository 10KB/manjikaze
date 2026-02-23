#!/bin/bash
set -e

# Import the 10KB Code Signing CA into the local GPG keyring and set it
# to ultimate trust. This enables GPG-based commit signature verification
# during manjikaze updates.
#
# Also configures GPG to auto-retrieve developer keys from keyservers,
# so signed commits from any CA-certified developer can be verified
# without manually importing their keys.

CA_KEY="$MANJIKAZE_DIR/assets/certs/10kb-code-signing-ca.asc"

if [[ ! -f "$CA_KEY" ]]; then
    status "Warning: Code Signing CA key not found at $CA_KEY. Skipping."
    return 0
fi

# Import the CA key (idempotent)
status "Importing 10KB Code Signing CA..."
gpg --import "$CA_KEY" 2>/dev/null || true

# Extract fingerprint and set ultimate trust
CA_FP=$(gpg --with-colons --import-options show-only --import "$CA_KEY" 2>/dev/null \
    | grep '^fpr:' | head -1 | cut -d: -f10)

if [[ -z "$CA_FP" ]]; then
    status "Warning: Could not determine CA key fingerprint. Skipping."
    return 0
fi

# Set ultimate trust (6) if not already set
if ! gpg --with-colons --list-keys "$CA_FP" 2>/dev/null | grep -q '^uid:u:'; then
    echo "$CA_FP:6:" | gpg --import-ownertrust 2>/dev/null
    status "CA key set to ultimate trust."
fi

# Configure auto-key-retrieve for on-demand developer key fetching
GPG_CONF="${GNUPGHOME:-$HOME/.gnupg}/gpg.conf"
if [[ -f "$GPG_CONF" ]] && ! grep -q 'auto-key-retrieve' "$GPG_CONF" 2>/dev/null; then
    echo "" >> "$GPG_CONF"
    echo "# Added by manjikaze: fetch unknown signing keys from keyserver automatically" >> "$GPG_CONF"
    echo "keyserver hkps://keys.openpgp.org" >> "$GPG_CONF"
    echo "auto-key-retrieve" >> "$GPG_CONF"
    status "GPG auto-key-retrieve configured."
fi

# Mark GPG CA as trusted in the state file
set_security_state "gpg_ca_trusted" "true"

status "10KB Code Signing CA configured. Commit signature verification is now active."
