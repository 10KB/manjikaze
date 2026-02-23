#!/bin/bash

source "$MANJIKAZE_DIR/app/installations/essential/cursor.sh"

current_track=$(get_cursor_release_track)

status "Current Cursor release track: $current_track"

new_track=$(gum choose "stable" "nightly" "stable+nightly" --header "Select Cursor release track:")

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

# Remove installations from tracks no longer selected
if [[ "$new_track" == "nightly" ]]; then
    uninstall_stable
elif [[ "$new_track" == "stable" ]]; then
    uninstall_nightly
fi

status "Cursor release track successfully changed to $new_track."

