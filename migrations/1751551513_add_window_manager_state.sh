#!/bin/bash
set -e

current_window_manager=$(get_window_manager)

if [ -z "$current_window_manager" ]; then
    status "No window manager found, setting to gnome"
    set_window_manager "gnome"
fi
