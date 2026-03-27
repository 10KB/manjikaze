#!/bin/bash
set -e

SLOT=${1:-2}

echo "This will configure YubiKey OTP slot $SLOT for HMAC-SHA1 challenge-response with touch required."
echo "WARNING: This will overwrite any existing configuration on slot $SLOT."
read -p "Continue? (y/N) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

ykman otp chalresp --touch --generate "$SLOT"
echo "YubiKey slot $SLOT configured for host-gate challenge-response."
