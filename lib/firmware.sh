#!/bin/bash
# Firmware for the BIOS, SSDs, docks and other devices comes from the LVFS through fwupd. The update
# only reports firmware updates: installing one can mean a reboot into the firmware updater, so
# manjikaze firmware installs them and asks first.

HOST_SECURITY_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/manjikaze/host-security.json"

ensure_fwupd() {
    if command -v fwupdmgr > /dev/null; then
        return 0
    fi

    status "Installing fwupd..."
    sudo pacman -S --needed --noconfirm --noprogressbar --quiet fwupd
}

# fwupd-refresh.timer is off on a default Manjaro installation, so the list of firmware is refreshed
# here. fwupdmgr exits with 2 when the list is recent enough already.
refresh_firmware_list() {
    local exit_code=0
    fwupdmgr refresh > /dev/null 2>&1 || exit_code=$?
    ((exit_code == 0 || exit_code == 2))
}

# Prints a line per device that has a firmware update: "name: installed → new".
list_firmware_updates() {
    fwupdmgr get-updates --json 2> /dev/null |
        jq -r '.Devices[]? | select((.Releases // []) | length > 0) | "\(.Name): \(.Version) → \(.Releases[0].Version)"' 2> /dev/null
}

# Prints the Host Security ID, such as "HSI:2 (v2.1.8)". An ! after the level marks runtime issues.
host_security_id() {
    fwupdmgr security --no-unreported-check 2> /dev/null |
        sed -e 's/\x1b\[[0-9;]*m//g' | sed -n 's/^Host Security ID: //p' | head -n 1
}

# Keeps fwupd's security report with the Host Security ID and the time of the check, so the
# security level of every workstation can be read from one file.
record_host_security() {
    local report hsi
    report=$(fwupdmgr security --json --no-unreported-check 2> /dev/null) || return 1
    hsi=$(host_security_id)
    mkdir -p "$(dirname "$HOST_SECURITY_FILE")" || return 1
    jq --arg hsi "$hsi" --arg checked "$(date --iso-8601=seconds)" \
        '. + {HostSecurityId: $hsi, Checked: $checked}' <<< "$report" > "$HOST_SECURITY_FILE.tmp" &&
        mv "$HOST_SECURITY_FILE.tmp" "$HOST_SECURITY_FILE"
}

# What the update shows about firmware. It installs nothing.
report_firmware() {
    if ! command -v fwupdmgr > /dev/null; then
        status "fwupd isn't installed, so the firmware wasn't checked. 'manjikaze firmware' installs it."
        return 0
    fi

    status "Checking for firmware updates..."
    refresh_firmware_list || status "Could not refresh the list of firmware updates."

    local hsi updates
    if record_host_security; then
        hsi=$(jq -r '.HostSecurityId // empty' "$HOST_SECURITY_FILE")
        if [[ -n $hsi ]]; then
            status "Host Security ID: $hsi."
        fi
    else
        status "Could not record the host security report."
    fi

    updates=$(list_firmware_updates)
    if [[ -n $updates ]]; then
        status "Firmware updates are available. Run 'manjikaze firmware' to install them:"
        sed 's/^/  /' <<< "$updates"
    else
        status "Firmware is up to date."
    fi
}
