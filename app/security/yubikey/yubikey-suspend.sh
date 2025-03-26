setup_yubikey_suspend=$(gum confirm "Do you want to set up YubiKey removal action?" --affirmative "Yes" --negative "No" --default=false && echo "true" || echo "false")

if [[ $setup_yubikey_suspend == "true" ]]; then
    yubikey_info=$(lsusb | grep -i "yubico" | head -n 1)
    if [ -z "$yubikey_info" ]; then
        status "No YubiKey detected. Please ensure your YubiKey is plugged in and try again."
        return 1
    fi

    mkdir -p ~/.config/systemd/user/
    tee ~/.config/systemd/user/yubikey-logout.service > /dev/null << EOL
[Unit]
Description=Logout user when YubiKey is removed

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'gdbus call --session --dest org.gnome.SessionManager --object-path /org/gnome/SessionManager --method org.gnome.SessionManager.Logout 1'

[Install]
WantedBy=default.target
EOL

    systemctl --user daemon-reload
    systemctl --user enable yubikey-logout.service

    sudo tee /usr/local/bin/yubikey-remove-action.sh > /dev/null << EOL
#!/bin/bash
ACTION=\$(cat /etc/yubikey-remove-action)
case \$ACTION in
    "Lock")
        /usr/bin/loginctl lock-sessions
        ;;
    "Suspend")
        /usr/bin/loginctl lock-sessions
        sleep 1  # Give a moment for the lock to take effect
        /usr/bin/systemctl suspend
        ;;
    "Logout")
        LOGGED_IN_USER=\$(who | awk '{print \$1}' | sort | uniq)
        sudo -u \$LOGGED_IN_USER XDG_RUNTIME_DIR=/run/user/\$(id -u \$LOGGED_IN_USER) systemctl --user start yubikey-logout.service
        ;;
esac
EOL
    sudo chmod +x /usr/local/bin/yubikey-remove-action.sh
    sudo tee /etc/udev/rules.d/90-yubikey-remove.rules > /dev/null << EOL
ACTION=="remove", SUBSYSTEM=="input", ATTRS{name}=="Yubico YubiKey OTP+FIDO+CCID", RUN+="/usr/bin/logger -t yubikey \"YubiKey removed - executing action\"", RUN+="/usr/bin/sudo -E /usr/local/bin/yubikey-remove-action.sh"
EOL

    ACTION=$(gum choose \
        "Lock" \
        "Suspend" \
        "Logout" \
        --header "Select action on YubiKey removal:")

    echo $ACTION | sudo tee /etc/yubikey-remove-action > /dev/null

    sudo udevadm control --reload-rules
    sudo udevadm trigger

    status "YubiKey removal action set to: $ACTION"
fi