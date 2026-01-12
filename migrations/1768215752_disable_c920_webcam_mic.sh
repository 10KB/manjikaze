#!/bin/bash
set -e

WIREPLUMBER_CONF_DIR="/etc/wireplumber/wireplumber.conf.d"
CONF_FILE="51-disable-c920-mic.conf"

status "Disabling Logitech C920 webcam microphone..."

sudo mkdir -p "$WIREPLUMBER_CONF_DIR"

sudo tee "$WIREPLUMBER_CONF_DIR/$CONF_FILE" > /dev/null << 'EOF'
# Disable the built-in microphone on Logitech C920 webcams
# The C920 mic has poor audio quality and often gets selected by accident in meetings

monitor.alsa.rules = [
  {
    matches = [
      {
        # Match the C920 audio input device by name pattern
        node.name = "~alsa_input.*C920.*"
      }
    ]
    actions = {
      update-props = {
        node.disabled = true
      }
    }
  }
]
EOF

status "Restarting WirePlumber to apply changes..."
systemctl --user restart wireplumber.service 2>/dev/null || true

status "Logitech C920 webcam microphone has been disabled."
status "Note: A logout/login may be required for the change to take effect."
