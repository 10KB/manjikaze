#!/bin/bash
set -e

# Document signing is no longer part of Manjikaze, so its CA leaves the system trust store.
# The anchor is removed only while it is the CA that migration 1771855244 installed.

TRUST_ANCHOR="/etc/ca-certificates/trust-source/anchors/10kb-document-signing-ca.crt"
CA_SHA256="a8cb1bb423e3897fbc416b84dc471fd9b3115044365932dca2e140fa2df24921"

if [[ ! -f "$TRUST_ANCHOR" ]]; then
    return 0
fi

if [[ $(sha256sum "$TRUST_ANCHOR" | cut -d ' ' -f 1) != "$CA_SHA256" ]]; then
    status "$TRUST_ANCHOR is not the 10KB Document Signing CA that Manjikaze installed, so it stays trusted."
    return 0
fi

status "Removing the 10KB Document Signing CA from the system trust store..."
sudo rm "$TRUST_ANCHOR"
sudo update-ca-trust

if [[ -d "$HOME/.pdf-signing" ]]; then
    status "Your personal signing certificate in $HOME/.pdf-signing is left alone. Remove it when you no longer need it."
fi
