#!/bin/bash

source "$MANJIKAZE_DIR/app/installations/essential/cursor.sh"

current_track=$(get_cursor_release_track)

status "Current Cursor release track: $current_track"

new_track=$(gum choose "stable" "latest" "nightly" "stable+nightly" --header "Select Cursor release track:")

if [[ -z "$new_track" ]]; then
    status "No selection made. Keeping current track."
    return 0
fi

if [[ "$new_track" == "$current_track" ]]; then
    status "Release track unchanged."
    return 0
fi

set_cursor_release_track "$new_track"
status "Release track changed to: $new_track"

status "Reinstalling Cursor with $new_track release track..."
install

status "Cursor release track successfully changed to $new_track."

