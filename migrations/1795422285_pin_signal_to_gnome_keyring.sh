#!/bin/bash
set -e

# Signal showed a database error in Hyprland: there it looked for its key outside GNOME Keyring.

if is_installed "signal-desktop"; then
    source "$MANJIKAZE_DIR/app/installations/optional/signal.sh"
    signal_pin_keyring
else
    status "Signal is not installed, skipping."
fi
