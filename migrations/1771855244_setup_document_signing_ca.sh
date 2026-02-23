#!/bin/bash
set -e

# Install the 10KB Document Signing CA certificate into the system trust
# store. This allows the system to verify documents and TLS certificates
# signed by the 10KB Document Signing CA.

CA_CERT="$MANJIKAZE_DIR/assets/certs/10kb-document-signing-ca.crt"
TRUST_ANCHOR="/etc/ca-certificates/trust-source/anchors/10kb-document-signing-ca.crt"

if [[ ! -f "$CA_CERT" ]]; then
    status "Warning: Document Signing CA certificate not found at $CA_CERT. Skipping."
    return 0
fi

if [[ -f "$TRUST_ANCHOR" ]]; then
    status "10KB Document Signing CA already installed in system trust store."
    return 0
fi

status "Installing 10KB Document Signing CA into system trust store..."
sudo cp "$CA_CERT" "$TRUST_ANCHOR"
sudo update-ca-trust

status "10KB Document Signing CA installed."
