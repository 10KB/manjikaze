source "$MANJIKAZE_DIR/lib/webcam-mic.sh"

if is_c920_mic_disabled; then
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
        if is_c920_mic_disabled; then
            status "Microphone is already disabled."
        else
            disable_c920_mic
        fi
        ;;
    "Enable microphone")
        if is_c920_mic_disabled; then
            enable_c920_mic
        else
            status "Microphone is already enabled."
        fi
        ;;
    *)
        status "No changes made."
        ;;
esac
