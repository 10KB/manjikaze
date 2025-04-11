setup_yubikey_suspend=$(gum confirm "Do you want to set up YubiKey removal action to lock your screen?" --affirmative "Yes" --negative "No" --default=false && echo "true" || echo "false")

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

    sudo tee /etc/udev/rules.d/90-yubikey-remove.rules > /dev/null << EOL
ACTION=="remove", SUBSYSTEM=="usb", ENV{PRODUCT}=="1050/407/*", RUN+="/bin/bash -c '/usr/local/bin/yubikey-remove-action.sh'"
EOL

    sudo udevadm control --reload-rules
    sudo udevadm trigger

    status "YubiKey removal action set to Lock."
    status "System will lock when YubiKey is physically removed."
fi