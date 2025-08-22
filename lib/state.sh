#!/bin/bash

# State file to store all persistent data like migrations
STATE_FILE="$MANJIKAZE_DIR/.manjikaze_state.json"

init_state_file() {
    if [[ ! -f "$STATE_FILE" ]]; then
        echo '{"migrations": {}, "audits": {}, "updates": {}, "window_manager": "gnome"}' > "$STATE_FILE"
    fi
}

get_migration_state() {
    local migration_id="$1"
    init_state_file
    jq -r ".migrations.\"$migration_id\" // \"\"" "$STATE_FILE"
}

set_migration_state() {
    local migration_id="$1"
    local timestamp="$2"
    init_state_file
    local temp_state=$(mktemp)
    jq --arg id "$migration_id" --arg ts "$timestamp" '.migrations += {($id): $ts}' "$STATE_FILE" > "$temp_state" && mv "$temp_state" "$STATE_FILE"
}

get_audit_state() {
    local audit_id="$1"
    init_state_file
    jq -r ".audits.\"$audit_id\" // \"\"" "$STATE_FILE"
}

set_audit_state() {
    local audit_id="$1"
    local timestamp="$2"
    init_state_file
    local temp_state=$(mktemp)
    jq --arg id "$audit_id" --arg ts "$timestamp" '.audits += {($id): $ts}' "$STATE_FILE" > "$temp_state" && mv "$temp_state" "$STATE_FILE"
}

get_update_check_time() {
    init_state_file
    jq -r '.updates.last_check // ""' "$STATE_FILE"
}

set_update_check_time() {
    local timestamp="$1"
    init_state_file
    local temp_state=$(mktemp)
    jq --arg ts "$timestamp" '.updates.last_check = $ts' "$STATE_FILE" > "$temp_state" && mv "$temp_state" "$STATE_FILE"
}

get_window_manager() {
    init_state_file
    jq -r '.window_manager // ""' "$STATE_FILE"
}

set_window_manager() {
    local window_manager="$1"
    init_state_file
    local temp_state=$(mktemp)
    jq --arg wm "$window_manager" '.window_manager = $wm' "$STATE_FILE" > "$temp_state" && mv "$temp_state" "$STATE_FILE"
}
