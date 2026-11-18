#!/bin/bash
# The Logitech C920 microphone sounds poor and is often picked by accident in meetings.

C920_MIC_CONF="/etc/wireplumber/wireplumber.conf.d/51-disable-c920-mic.conf"

is_c920_mic_disabled() {
    [[ -f "$C920_MIC_CONF" ]]
}

disable_c920_mic() {
    status "Disabling Logitech C920 webcam microphone..."

    sudo mkdir -p "$(dirname "$C920_MIC_CONF")"

    sudo tee "$C920_MIC_CONF" > /dev/null << 'EOF'
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

    systemctl --user restart wireplumber.service 2>/dev/null || true
    status "Logitech C920 webcam microphone has been disabled."
}

enable_c920_mic() {
    status "Enabling Logitech C920 webcam microphone..."

    sudo rm -f "$C920_MIC_CONF"

    systemctl --user restart wireplumber.service 2>/dev/null || true
    status "Logitech C920 webcam microphone has been enabled."
}
