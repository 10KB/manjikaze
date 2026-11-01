setup_yubikey_suspend=$(gum confirm "Do you want to lock your session when the YubiKey is removed?" --affirmative "Yes" --negative "No" --default=false && echo "true" || echo "false")

if [[ $setup_yubikey_suspend == "true" ]]; then
    yubikey_info=$(lsusb | grep -i "yubico" | head -n 1)
    if [ -z "$yubikey_info" ]; then
        status "No YubiKey detected. Please ensure your YubiKey is plugged in and try again."
        return 1
    fi

    sudo tee /usr/local/bin/yubikey-remove-action.sh > /dev/null << EOL
#!/bin/bash
# Only lock sessions, no other options
/usr/bin/loginctl lock-sessions
EOL

    sudo chmod +x /usr/local/bin/yubikey-remove-action.sh

    sudo tee /etc/udev/rules.d/90-yubikey-actions.rules > /dev/null << EOL
# Lock on removal
ACTION=="remove", SUBSYSTEM=="usb", ENV{PRODUCT}=="1050/407/*", RUN+="/bin/bash -c '/usr/local/bin/yubikey-remove-action.sh'"
EOL

    # Unlocking on insertion would skip the PIN; you unlock with the PIN or your password.
    sudo rm -f /usr/local/bin/yubikey-insert-action.sh

    sudo udevadm control --reload-rules
    sudo udevadm trigger

    status "YubiKey actions configured successfully."
    status "System will lock when YubiKey is physically removed."
fi
