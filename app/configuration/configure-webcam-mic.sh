WIREPLUMBER_CONF_DIR="/etc/wireplumber/wireplumber.conf.d"
CONF_FILE="51-disable-c920-mic.conf"
CONF_PATH="$WIREPLUMBER_CONF_DIR/$CONF_FILE"

is_mic_disabled() {
    [[ -f "$CONF_PATH" ]]
}

disable_mic() {
    status "Disabling Logitech C920 webcam microphone..."

    sudo mkdir -p "$WIREPLUMBER_CONF_DIR"

    sudo tee "$CONF_PATH" > /dev/null << 'EOF'
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

enable_mic() {
    status "Enabling Logitech C920 webcam microphone..."

    sudo rm -f "$CONF_PATH"

    systemctl --user restart wireplumber.service 2>/dev/null || true
    status "Logitech C920 webcam microphone has been enabled."
}

if is_mic_disabled; then
    current_status="disabled"
else
    current_status="enabled"
fi

choice=$(gum choose --header "Logitech C920 webcam microphone is currently: $current_status" \
    "Disable microphone" \
    "Enable microphone" \
    "Cancel")

case "$choice" in
    "Disable microphone")
        if is_mic_disabled; then
            status "Microphone is already disabled."
        else
            disable_mic
        fi
        ;;
    "Enable microphone")
        if is_mic_disabled; then
            enable_mic
        else
            status "Microphone is already enabled."
        fi
        ;;
    *)
        status "No changes made."
        ;;
esac
