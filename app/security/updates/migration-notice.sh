#!/bin/bash

MIGRATION_NOTICE_UNIT="manjikaze-migration-notice.service"

# A user service that runs manjikaze migrate --notify after every login, in GNOME and in Hyprland.
install_migration_notice() {
    local unit_dir="$HOME/.config/systemd/user"
    mkdir -p "$unit_dir"
    cat > "$unit_dir/$MIGRATION_NOTICE_UNIT" << EOF
[Unit]
Description=Notice about pending Manjikaze migrations
After=graphical-session.target
PartOf=graphical-session.target

[Service]
Type=exec
ExecStart=$MANJIKAZE_DIR/bin/manjikaze migrate --notify

[Install]
WantedBy=graphical-session.target
EOF

    systemctl --user daemon-reload
    systemctl --user enable "$MIGRATION_NOTICE_UNIT"
}

remove_migration_notice() {
    systemctl --user disable "$MIGRATION_NOTICE_UNIT" 2> /dev/null || true
    rm -f "$HOME/.config/systemd/user/$MIGRATION_NOTICE_UNIT"
    systemctl --user daemon-reload
}
