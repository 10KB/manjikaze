#!/bin/bash
set -e

# Update state file structure for updates
if [[ -f "$STATE_FILE" ]] && ! jq -e '.updates' "$STATE_FILE" > /dev/null 2>&1; then
    status "Adding updates tracking to state file..."
    local temp_state=$(mktemp)
    jq '. += {"updates": {}}' "$STATE_FILE" > "$temp_state" && mv "$temp_state" "$STATE_FILE"
fi

# Optionally configure system update checks
source "$MANJIKAZE_DIR/app/security/updates/configure-update-checker.sh"
