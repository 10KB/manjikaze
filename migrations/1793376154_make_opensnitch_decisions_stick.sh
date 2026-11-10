#!/bin/bash
set -e

# OpenSnitch 1.7 preselects "12h" in its prompt: such a rule lives in memory and is
# gone after a restart, so the same apps ask again. Index 8 is "forever" in 1.7.
if ! is_installed "opensnitch"; then
    status "OpenSnitch is not installed, skipping."
    return 0
fi

opensnitch_version=$(pacman -Q opensnitch | awk '{print $2}')
if [[ "$opensnitch_version" != 1.7.* ]]; then
    status "OpenSnitch $opensnitch_version is not 1.7, skipping."
    return 0
fi

opensnitch_settings="$HOME/.config/opensnitch/settings.conf"
mkdir -p "$(dirname "$opensnitch_settings")"
touch "$opensnitch_settings"
awk -v key=default_duration -v value=8 '
    /^\[/ {
        if (global && !done) { print key "=" value; done = 1 }
        global = ($0 == "[global]")
    }
    global && index($0, key "=") == 1 {
        if (!done) { print key "=" value; done = 1 }
        next
    }
    { print }
    END {
        if (!done) {
            if (!global) print "[global]"
            print key "=" value
        }
    }
' "$opensnitch_settings" > "$opensnitch_settings.new"
mv "$opensnitch_settings.new" "$opensnitch_settings"
status "OpenSnitch now remembers decisions forever by default; restart its UI to apply."

opensnitch_changed=false

# Without a queue, exec events are dropped while the eBPF workers are busy, and
# connections are attributed to the wrong process.
opensnitch_config=/etc/opensnitchd/default-config.json
if [[ "$(jq -r '.Ebpf.QueueEventsSize // "missing"' "$opensnitch_config" 2>/dev/null)" == "0" ]]; then
    opensnitch_temp=$(mktemp)
    jq '.Ebpf.QueueEventsSize = 1024' "$opensnitch_config" > "$opensnitch_temp"
    sudo install -m 644 "$opensnitch_temp" "$opensnitch_config"
    rm -f "$opensnitch_temp"
    opensnitch_changed=true
fi

# Spotify changes hostnames all the time and Dropbox updates itself into a new
# directory, so rules per host or per path keep asking.
opensnitch_allow_process() {
    local path="/etc/opensnitchd/rules/manjikaze-$1.json"
    [[ -f "$path" ]] && return 0
    jq -n --arg name "manjikaze-$1" --arg description "$2" --arg type "$3" --arg data "$4" \
        --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '{
            created: $now, updated: $now, name: $name, description: $description,
            enabled: true, precedence: false, nolog: false, action: "allow", duration: "always",
            operator: {type: $type, operand: "process.path", sensitive: false, data: $data, list: []}
        }' | sudo tee "$path" > /dev/null
    opensnitch_changed=true
}

if is_installed "spotify"; then
    opensnitch_allow_process spotify "Spotify, installed by Manjikaze" simple /opt/spotify/spotify
fi
if is_installed "dropbox"; then
    opensnitch_allow_process dropbox "Dropbox, any version it updates itself to" regexp \
        '^/home/[^/]+/\.dropbox-dist/dropbox-lnx\.[^/]+/dropbox$'
fi
unset -f opensnitch_allow_process

if [[ "$opensnitch_changed" == true ]]; then
    sudo systemctl try-restart opensnitchd
    status "OpenSnitch daemon restarted with the new rules and settings."
fi
