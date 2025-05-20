#!/bin/bash
set -e

status "Checking if update checker is already configured..."
if systemctl --user is-enabled manjikaze-update-check.timer &>/dev/null; then
    status "Update checker is already configured."
    return 0
fi

if ! gum confirm "Would you like to enable weekly system update checks?"; then
    status "Weekly update checks not enabled. You can enable them later from the security menu."
    return 0
fi

status "Ensuring systemd user directory exists..."
mkdir -p "$HOME/.config/systemd/user"

status "Creating systemd service for update checking..."
cat > "$HOME/.config/systemd/user/manjikaze-update-check.service" << EOF
[Unit]
Description=Check for system updates
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=${MANJIKAZE_DIR}/app/security/updates/check-updates.sh
Environment=DISPLAY=:0

[Install]
WantedBy=default.target
EOF

status "Creating systemd timer for weekly update checks..."
cat > "$HOME/.config/systemd/user/manjikaze-update-check.timer" << EOF
[Unit]
Description=Check for system updates weekly

[Timer]
OnBootSec=5min
OnUnitActiveSec=1w
Persistent=true

[Install]
WantedBy=timers.target
EOF

status "Enabling and starting update check timer..."
systemctl --user daemon-reload
systemctl --user enable manjikaze-update-check.timer
systemctl --user start manjikaze-update-check.timer

status "Running initial update check..."
"$MANJIKAZE_DIR/app/security/updates/check-updates.sh"

status "Update checker has been configured to run weekly."
