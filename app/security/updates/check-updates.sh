#!/bin/bash
# Check for pending system updates and notify the user
set -e

if [ -z "$XDG_RUNTIME_DIR" ]; then
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
fi

if [ -z "$DISPLAY" ]; then
    export DISPLAY=:0
fi

if [ -z "$MANJIKAZE_DIR" ]; then
    SCRIPT_PATH=$(readlink -f "$0")
    SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
    export MANJIKAZE_DIR=$(cd "$SCRIPT_DIR/../../../" && pwd)
fi

source "$MANJIKAZE_DIR/lib/common.sh"
source "$MANJIKAZE_DIR/lib/state.sh"

check_for_updates() {
    local repo_updates aur_updates=0

    # This runs without a terminal, so sudo can't ask for a password. checkupdates syncs a copy of
    # the package databases as the user, which also avoids a sync without an upgrade.
    if command -v checkupdates >/dev/null 2>&1; then
        repo_updates=$(checkupdates 2>/dev/null | wc -l)
    else
        repo_updates=$(pacman -Qu 2>/dev/null | wc -l)
    fi

    if command -v yay >/dev/null 2>&1; then
        aur_updates=$(yay -Qua | wc -l)
    fi

    local total_updates=$((repo_updates + aur_updates))

    echo "$total_updates"
}

send_notification() {
    local total_updates="$1" action

    if [ "$total_updates" -gt 0 ]; then
        # Waits until the notification is closed and prints the name of the clicked action, if any.
        action=$(notify-send \
            --app-name="Manjikaze" \
            --icon=system-software-update \
            --urgency=normal \
            --action="update=Update Now" \
            "System Updates Available" \
            "$total_updates update(s) are available for your system.") || return 0

        # The update asks questions, and this service has no terminal of its own.
        if [[ $action == update ]]; then
            open_in_terminal "$MANJIKAZE_DIR/bin/manjikaze" update || true
        fi
    fi
}

should_notify() {
    local current_time=$(date +%s)
    local last_check=$(get_update_check_time)

    if [ -z "$last_check" ]; then
        set_update_check_time "$current_time"
        return 0
    fi

    # Notify once per week = 604800 seconds
    local diff=$((current_time - last_check))

    if [ "$diff" -ge 604800 ]; then
        set_update_check_time "$current_time"
        return 0
    fi

    return 1
}

if should_notify; then
    total_updates=$(check_for_updates)
    if [ "$total_updates" -gt 0 ]; then
        send_notification "$total_updates"
    fi
fi
