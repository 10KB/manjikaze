#!/bin/bash

LEGACY_MANJIKAZE_DIR="$HOME/.manjikaze"

# Prepares a package install for the current user. Safe to rerun; it never
# removes the earlier git install.
setup_package_install() {
    if ! is_package_install; then
        return 0
    fi

    migrate_legacy_data
    remove_legacy_desktop_entry
    repoint_update_checker

    if [[ -e /usr/local/bin/manjikaze ]]; then
        status "Warning: /usr/local/bin/manjikaze shadows the package. Remove it with: sudo rm /usr/local/bin/manjikaze"
    fi
}

# Copies the state and secrets of an earlier git install into the data directory.
migrate_legacy_data() {
    if [[ ! -d "$LEGACY_MANJIKAZE_DIR" || -f "$STATE_FILE" ]]; then
        return 0
    fi

    local legacy_state="$LEGACY_MANJIKAZE_DIR/.manjikaze_state.json"
    local legacy_secrets="$LEGACY_MANJIKAZE_DIR/secrets"
    local copied=false

    mkdir -p "$MANJIKAZE_DATA_DIR"

    if [[ -d "$legacy_secrets" && -n "$(ls -A "$legacy_secrets")" ]]; then
        # Never overwrite secrets that are already in the data directory
        if [[ -z "$(ls -A "$MANJIKAZE_DATA_DIR/secrets" 2>/dev/null)" ]]; then
            mkdir -p "$MANJIKAZE_DATA_DIR/secrets"
            cp -a "$legacy_secrets/." "$MANJIKAZE_DATA_DIR/secrets/"
            # Git installs created this directory without restricting access
            chmod 700 "$MANJIKAZE_DATA_DIR/secrets"
            copied=true
        fi
        if ! diff -rq "$legacy_secrets" "$MANJIKAZE_DATA_DIR/secrets" >/dev/null; then
            status "Error: $MANJIKAZE_DATA_DIR/secrets differs from $legacy_secrets. Compare them before continuing."
            return 1
        fi
    fi

    # The state file comes last: once it exists, this migration counts as done.
    if [[ -f "$legacy_state" ]]; then
        cp -a "$legacy_state" "$STATE_FILE.tmp"
        mv "$STATE_FILE.tmp" "$STATE_FILE"
        copied=true
    fi

    if [[ "$copied" == true ]]; then
        status "Copied state and secrets from $LEGACY_MANJIKAZE_DIR to $MANJIKAZE_DATA_DIR."
        status "Remove $LEGACY_MANJIKAZE_DIR once Manjikaze works as expected."
    fi
}

remove_legacy_desktop_entry() {
    local entry="$HOME/.local/share/applications/manjikaze.desktop"

    if [[ -f "$entry" ]] && grep -q "^Icon=$LEGACY_MANJIKAZE_DIR/" "$entry"; then
        rm "$entry"
        status "Removed the desktop entry of the earlier git install."
    fi
}

repoint_update_checker() {
    local unit="$HOME/.config/systemd/user/manjikaze-update-check.service"
    local exec_start="ExecStart=$MANJIKAZE_DIR/app/security/updates/check-updates.sh"

    if [[ ! -f "$unit" ]] || grep -qxF "$exec_start" "$unit"; then
        return 0
    fi

    sed -i "s|^ExecStart=.*/app/security/updates/check-updates.sh$|$exec_start|" "$unit"
    systemctl --user daemon-reload
    status "Pointed the update checker at $MANJIKAZE_DIR."
}
