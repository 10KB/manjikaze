#!/bin/bash
set -e

# swaync runs update-command as /bin/sh -c "<command>", so the double quotes in the commands that read
# whether Wi-Fi and Bluetooth are on broke them. The quick settings toggles kept a stale state.

swaync_config="$HOME/.config/swaync/config.json"

if [[ ! -f $swaync_config ]]; then
    status "No swaync configuration to update, skipping."
    return 0
fi

old_wifi='"update-command": "sh -c '\''[ \"$(nmcli radio wifi)\" = enabled ] && echo true || echo false'\''"'
new_wifi='"update-command": "nmcli radio wifi | grep -qx enabled && echo true || echo false"'
old_bluetooth='"update-command": "sh -c '\''bluetoothctl show | grep -q \"Powered: yes\" && echo true || echo false'\''"'
new_bluetooth='"update-command": "bluetoothctl show | grep -q '\''Powered: yes'\'' && echo true || echo false"'

config=$(<"$swaync_config")
updated=${config//"$old_wifi"/"$new_wifi"}
updated=${updated//"$old_bluetooth"/"$new_bluetooth"}

if [[ $updated == "$config" ]]; then
    status "The swaync configuration has no default Wi-Fi or Bluetooth toggle to update, skipping."
    return 0
fi

printf '%s\n' "$updated" >"$swaync_config"
swaync-client --reload-config >/dev/null 2>&1 || true
status "The quick settings now show whether Wi-Fi and Bluetooth are on."
