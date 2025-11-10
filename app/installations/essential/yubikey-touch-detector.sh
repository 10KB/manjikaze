install() {
    install_package "yubikey-touch-detector" aur
    install_package "libnotify" repo

    mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/yubikey-touch-detector"

    cat > "${XDG_CONFIG_HOME:-$HOME/.config}/yubikey-touch-detector/service.conf" << EOF
YUBIKEY_TOUCH_DETECTOR_VERBOSE=false
YUBIKEY_TOUCH_DETECTOR_LIBNOTIFY=true
YUBIKEY_TOUCH_DETECTOR_STDOUT=false
YUBIKEY_TOUCH_DETECTOR_NOSOCKET=false
EOF

    systemctl --user daemon-reload
    systemctl --user enable --now yubikey-touch-detector.service
}

uninstall() {
    uninstall_package "yubikey-touch-detector" aur
    uninstall_package "libnotify" repo
}
