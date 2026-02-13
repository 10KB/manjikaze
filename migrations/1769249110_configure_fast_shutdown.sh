#!/bin/bash
set -e

# Reduce systemd shutdown timeout from 90s to 5s
# This prevents long waits when services don't stop gracefully

CONF_DIR="/etc/systemd/system.conf.d"
CONF_FILE="$CONF_DIR/10-faster-shutdown.conf"

if [[ -f "$CONF_FILE" ]]; then
    status "Fast shutdown configuration already exists, skipping."
    return 0
fi

status "Configuring faster shutdown timeout (5s instead of 90s)..."

sudo mkdir -p "$CONF_DIR"

cat <<EOF | sudo tee "$CONF_FILE" > /dev/null
[Manager]
DefaultTimeoutStopSec=5s
EOF

sudo systemctl daemon-reload

status "Fast shutdown configured successfully."
