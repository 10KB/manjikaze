#!/bin/bash

source "$MANJIKAZE_DIR/lib/firmware.sh"

update_firmware() {
    if ! ensure_fwupd; then
        status "Could not install fwupd, which updates the firmware."
        return 1
    fi

    status "Refreshing the list of firmware updates..."
    refresh_firmware_list || status "Could not refresh the list of firmware updates, so this uses the list fwupd already has."

    record_host_security || status "Could not record the host security report."
    local hsi updates
    hsi=$(host_security_id)
    if [[ -n $hsi ]]; then
        status "Host Security ID: $hsi. Run 'fwupdmgr security' for what it is made of."
    fi

    updates=$(list_firmware_updates)
    if [[ -z $updates ]]; then
        status "All firmware is up to date."
        return 0
    fi

    status "Firmware updates are available:"
    sed 's/^/  /' <<< "$updates"
    status "Keep the computer on AC power. Some updates finish during a reboot, which fwupd asks about."
    if ! gum confirm "Install the firmware updates?"; then
        status "Firmware update cancelled."
        return 0
    fi

    sudo fwupdmgr update
}

firmware_exit_code=0
update_firmware || firmware_exit_code=$?
return "$firmware_exit_code"
