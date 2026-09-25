#!/bin/bash

POLICY_FILE="$HOME/.config/host-gate/policy.json"

if [ ! -f "$POLICY_FILE" ]; then
    if [ -f "$MANJIKAZE_DIR/host-gate/configs/default-policy.json" ]; then
        mkdir -p "$HOME/.config/host-gate"
        cp "$MANJIKAZE_DIR/host-gate/configs/default-policy.json" "$POLICY_FILE"
        status "Created default policy config at $POLICY_FILE"
    else
        status "Host gate is not installed. Install it first via Setup > Choose optional apps."
        return 1
    fi
fi

status "Opening host gate policy config for editing..."
status "After saving, restart the daemon: systemctl --user restart host-gate"

cursor "$POLICY_FILE" --wait

if systemctl --user is-active host-gate.service &>/dev/null; then
    if gum confirm "Restart host-gate daemon to apply changes?"; then
        systemctl --user restart host-gate.service
        status "Host gate daemon restarted."
    fi
fi
