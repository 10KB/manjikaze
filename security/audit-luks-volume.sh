verify_luks_encryption() {
    root_device=$(findmnt -no SOURCE /)
    if [[ $root_device == /dev/mapper/* ]]; then
        encrypted_device=$(lsblk -npo NAME,PKNAME | grep "$root_device" | awk '{print $2}')
        if sudo cryptsetup isLuks "$encrypted_device"; then
            echo "Verification successful: The system is running on a LUKS encrypted volume."
            echo "Encrypted device: $encrypted_device"
            echo "Mapped device: $root_device"
        else
            echo "Verification failed: The root device is mapped but not LUKS encrypted."
        fi
    else
        echo "Verification failed: The system is not running on an encrypted volume."
    fi
}