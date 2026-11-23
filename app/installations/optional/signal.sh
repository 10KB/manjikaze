SIGNAL_FLAGS_FILE="$HOME/.config/signal-desktop-flags.conf"

install() {
    install_package "signal-desktop" aur
    signal_pin_keyring
}

uninstall() {
    uninstall_package "signal-desktop" aur
}

# Signal encrypts its database with a key from the OS keyring, and Electron picks that keyring by
# desktop. It doesn't know Hyprland and falls back to a plain-text store there, so Signal refuses
# to open the database it created in GNOME. GNOME Keyring runs in both sessions.
signal_pin_keyring() {
    if grep -qs -- '--password-store=' "$SIGNAL_FLAGS_FILE"; then
        status "Signal already has a password store in $SIGNAL_FLAGS_FILE."
        return 0
    fi

    mkdir -p "$(dirname "$SIGNAL_FLAGS_FILE")"
    echo '--password-store=gnome-libsecret' >> "$SIGNAL_FLAGS_FILE"
    status "Signal now keeps its database key in GNOME Keyring, in GNOME and in Hyprland."
}
