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
    sudo pacman -Sy --quiet --noconfirm --noprogressbar >/dev/null 2>&1

    local repo_updates=$(pacman -Qu | wc -l)
    local aur_updates=0

    if command -v yay >/dev/null 2>&1; then
        aur_updates=$(yay -Qua | wc -l)
    fi

    local total_updates=$((repo_updates + aur_updates))

    echo "$total_updates"
}

send_notification() {
    local total_updates="$1"

    if [ "$total_updates" -gt 0 ]; then
        local notify_cmd="notify-send"
        local action_str=""

        notify-send \
            --app-name="Manjikaze" \
            --icon=system-software-update \
            --urgency=normal \
            "System Updates Available" \
            "$total_updates update(s) are available for your system.\nClick to update now." \
            -A "update:Update Now"

        if [ $? -eq 0 ]; then
            manjikaze update
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
