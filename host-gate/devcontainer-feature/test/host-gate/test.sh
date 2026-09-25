#!/bin/bash
set -e

# Verify client binary is installed
if ! command -v host-gate-client &> /dev/null; then
    echo "FAIL: host-gate-client not found in PATH"
    exit 1
fi

# Verify environment variables are set
if [ -z "$HOST_GATE_SOCKET" ]; then
    echo "FAIL: HOST_GATE_SOCKET not set"
    exit 1
fi

if [ -z "$HOST_GATE_HMAC_KEY" ]; then
    echo "FAIL: HOST_GATE_HMAC_KEY not set"
    exit 1
fi

echo "PASS: host-gate feature installed correctly"
