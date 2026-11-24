#!/bin/bash
set -e

# Rootless Docker is the standard now. The rootful daemon's socket gave everyone in the docker group
# root without a password, which also bypassed a YubiKey on sudo. The rootful daemon goes off only
# once rootless Docker works, so Docker never stops working.

if ! is_installed docker; then
    return 0
fi

source "$MANJIKAZE_DIR/lib/docker.sh"

if ! configure_rootless_docker; then
    return 1
fi
leave_rootful_docker
