#!/bin/bash

# State file to store all persistent data like migrations
STATE_FILE="$MANJIKAZE_DIR/.manjikaze_state.json"

init_state_file() {
    if [[ ! -f "$STATE_FILE" ]]; then
        echo '{"migrations": {}, "audits": {}, "updates": {}}' > "$STATE_FILE"
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

get_cursor_release_track() {
    init_state_file
    jq -r '.settings.cursor_release_track // "stable"' "$STATE_FILE"
}

set_cursor_release_track() {
    local track="$1"
    init_state_file
    local temp_state=$(mktemp)
    jq --arg track "$track" '.settings.cursor_release_track = $track' "$STATE_FILE" > "$temp_state" && mv "$temp_state" "$STATE_FILE"
}
