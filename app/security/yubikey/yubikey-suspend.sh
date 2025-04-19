setup_yubikey_suspend=$(gum confirm "Do you want to set up YubiKey actions (lock on removal, unlock on insertion)?" --affirmative "Yes" --negative "No" --default=false && echo "true" || echo "false")

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
    sudo tee /usr/local/bin/yubikey-insert-action.sh > /dev/null << EOL
#!/bin/bash
# Verify YubiKey challenge/response authentication and then unlock sessions
pamtester login \$(/usr/bin/loginctl list-users --no-pager --no-legend | head -n 1 | /usr/bin/cut -f2 -d ' ') authenticate && /usr/bin/loginctl unlock-sessions
EOL

    sudo chmod +x /usr/local/bin/yubikey-remove-action.sh
    sudo chmod +x /usr/local/bin/yubikey-insert-action.sh

    sudo tee /etc/udev/rules.d/90-yubikey-actions.rules > /dev/null << EOL
# Lock on removal
ACTION=="remove", SUBSYSTEM=="usb", ENV{PRODUCT}=="1050/407/*", RUN+="/bin/bash -c '/usr/local/bin/yubikey-remove-action.sh'"
# Unlock on insertion
ACTION=="add", SUBSYSTEM=="usb", ENV{PRODUCT}=="1050/407/*", RUN+="/bin/bash -c '/usr/local/bin/yubikey-insert-action.sh'"
EOL

    sudo udevadm control --reload-rules
    sudo udevadm trigger

    status "YubiKey actions configured successfully."
    status "System will lock when YubiKey is physically removed."
    status "System will unlock when YubiKey is inserted after successful challenge/response verification."
fi