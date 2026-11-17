#!/bin/bash
set -e

# swaync runs commands as /bin/sh -c "<command>", so the double quotes in the quick settings commands
# ended its quoting. The commands that read whether Wi-Fi and Bluetooth are on failed, and the toggles
# kept a stale state. Each default command is replaced only while it is unchanged.

swaync_config="$HOME/.config/swaync/config.json"

if [[ ! -f $swaync_config ]]; then
    status "No swaync configuration to update, skipping."
    return 0
fi

config=$(<"$swaync_config")
updated=$config

replace() {
    updated=${updated//"$1"/"$2"}
}

replace '"update-command": "sh -c '\''[ \"$(nmcli radio wifi)\" = enabled ] && echo true || echo false'\''"' \
    '"update-command": "nmcli radio wifi | grep -qx enabled && echo true || echo false"'
replace '"update-command": "sh -c '\''bluetoothctl show | grep -q \"Powered: yes\" && echo true || echo false'\''"' \
    '"update-command": "bluetoothctl show | grep -q '\''Powered: yes'\'' && echo true || echo false"'

for action in \
    'nmcli radio wifi on || nmcli radio wifi off' \
    'bluetoothctl power on || bluetoothctl power off' \
    'wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0 || wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 1' \
    'manjikaze-hypr-stay-awake on || manjikaze-hypr-stay-awake off'; do
    replace '"command": "sh -c '\''[ \"$SWAYNC_TOGGLE_STATE\" = true ] && '"$action"\''"' \
        '"command": "[ $SWAYNC_TOGGLE_STATE = true ] && '"$action"'"'
done

if [[ $updated == "$config" ]]; then
    status "The swaync configuration has no default quick settings commands to update, skipping."
    return 0
fi

printf '%s\n' "$updated" >"$swaync_config"
swaync-client --reload-config >/dev/null 2>&1 || true
status "The quick settings now show whether Wi-Fi and Bluetooth are on."
