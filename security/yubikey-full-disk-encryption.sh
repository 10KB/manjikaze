configure_full_disk_encryption() {
    setup_full_disk_encryption=$(gum confirm "Do you want to set up full disk encryption with a YubiKey?" --affirmative "Yes" --negative "No" --default=false)

    if [ $? -eq 0 ]; then
        if ! pacman -Qi yubikey-full-disk-encryption &> /dev/null; then
            sudo pacman -S yubikey-full-disk-encryption --noconfirm
        fi

        encrypted_device_name=$(findmnt -no SOURCE / | sed 's/\/dev\/mapper\///')
        encrypted_device_location="$(lsblk -npo NAME,PKNAME | grep "$encrypted_device_name" | awk '{print $2}')"

        sudo sed -i 's/^#YKFDE_CHALLENGE_SLOT="2"/YKFDE_CHALLENGE_SLOT="2"/' /etc/ykfde.conf
        sudo sed -i 's/^#YKFDE_CHALLENGE=""/YKFDE_CHALLENGE="'$(openssl rand -hex 32)'"/' /etc/ykfde.conf

        echo "Checking available LUKS key slots..."
        available_slots=$(sudo cryptsetup luksDump "$encrypted_device_location" | grep -E "Key Slot [0-7]: DISABLED" | cut -d: -f1 | awk '{print $3}')

        if [ -z "$available_slots" ]; then
            echo "Error: No available LUKS key slots. Please free up a slot before continuing."
            return 1
        fi

        echo "Available LUKS key slots: $available_slots"
        chosen_slot=$(gum input --prompt "Enter the key slot number to use for YubiKey (e.g., 1, 2, 3, etc.): ")

        if ! echo "$available_slots" | grep -q "$chosen_slot"; then
            echo "Error: Invalid or unavailable key slot selected."
            return 1
        fi

        sudo ykfde-enroll -d "$encrypted_device_location" -s "$chosen_slot"

        if ! grep -q "ykfde" /etc/mkinitcpio.conf; then
            sudo sed -i 's/\(^HOOKS=([^)]*\)encrypt/\1ykfde encrypt/' /etc/mkinitcpio.conf
        fi

        sudo mkinitcpio -P

        echo "Full disk encryption with YubiKey has been configured."
        echo "Please ensure your YubiKey is inserted during boot."
    fi
}