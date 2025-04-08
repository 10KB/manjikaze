#!/bin/bash
# Full Disk Encryption Audit
set -e

# Handle interrupt signal
trap 'echo -e "\nAudit interrupted by user"; exit 1' INT

root_device=$(findmnt -no SOURCE /)
if [[ $root_device == /dev/mapper/* ]]; then
    # Get the physical device that's encrypted
    encrypted_device=$(lsblk -npo NAME,PKNAME | grep "$root_device" | awk '{print $NF}')

    # Check if the physical device is LUKS encrypted
    if sudo cryptsetup isLuks "$encrypted_device"; then
        echo "Verification successful: The system is running on a LUKS encrypted volume."
        echo "Encrypted device: $encrypted_device"
        echo "Mapped device: $root_device"
        exit 0
    else
        echo "Verification failed: The root device is mapped but not LUKS encrypted."
        exit 1
    fi
else
    echo "Verification failed: The system is not running on an encrypted volume."
    exit 1
fi
