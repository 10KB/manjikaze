setup_gnome=$(gum confirm "Do you want to configure GNOME and extensions?" --affirmative "Yes" --negative "No" --default=false && echo "true" || echo "false")

if [[ $setup_gnome == "true" ]]; then
    status "Configuring GNOME and extensions..."

    # Show week numbers in the calendar
    gsettings set org.gnome.desktop.calendar show-weekdate true

    # Set global shortcut Super + E to open file explorer at home directory
    gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']"

    # Set global shortcut Super + W to open web browser
    gsettings set org.gnome.settings-daemon.plugins.media-keys www "['<Super>w']"

    # Center new windows in the middle of the screen
    gsettings set org.gnome.mutter center-new-windows true

    # Set Cascadia Mono as the default monospace font
    gsettings set org.gnome.desktop.interface monospace-font-name 'CaskaydiaMono Nerd Font 10'

    # Make it easy to maximize like you can fill left/right
    gsettings set org.gnome.desktop.wm.keybindings maximize "['<Super>Up']"

    # Install gnome extension manager
    install_package "extension-manager" "aur"
    install_package "gnome-extensions-cli" "aur"

    # Disable Pamac Updates Indicator extension (buggy - can show persistent icon)
    if gnome-extensions list | grep -q "pamac-updates@manjaro.org"; then
        gnome-extensions disable "pamac-updates@manjaro.org"
    fi

    # Clipboard history extension
    gext install clipboard-indicator@tudmotu.com

    # Tactile window organizer extension
    gext install tactile@lundal.io

    # Remove window decorations (Cursor and VScode)
    gext install undecorate@sun.wxg@gmail.com

    # Make it easy to resize undecorated windows
    gsettings set org.gnome.desktop.wm.keybindings begin-resize "['<Super>BackSpace']"

    # Named workspaces switcher
    gext install space-bar@luchrioh

    # Use 3 fixed workspaces instead of dynamic mode
    gsettings set org.gnome.mutter dynamic-workspaces false
    gsettings set org.gnome.desktop.wm.preferences num-workspaces 3

    # Use super for workspaces
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']"

    # Alphabetical app grid
    gext install AlphabeticalAppGrid@stuarthayhurst

    # Configure Flameshot shortcut (Super + Print)
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/flameshot/']"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/flameshot/ name "Flameshot"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/flameshot/ command "flameshot gui"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/flameshot/ binding "<Super>Print"

    # App doesn't do anything when started from the app grid
    sudo rm -rf /usr/share/applications/org.flameshot.Flameshot.desktop

    # Remove the ImageMagick icon
    sudo rm -rf /usr/share/applications/display-im6.q16.desktop

    # Set dark mode preference
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

    # Configure background image
    BACKGROUND_SRC="$MANJIKAZE_DIR/assets/background.jpg"
    BACKGROUND_DEST_DIR="$HOME/.local/share/backgrounds"
    BACKGROUND_DEST_PATH="$BACKGROUND_DEST_DIR/manjikaze-background.jpg"

    if [ -f "$BACKGROUND_SRC" ]; then
        # Create backgrounds directory if it doesn't exist
        if [ ! -d "$BACKGROUND_DEST_DIR" ]; then
            mkdir -p "$BACKGROUND_DEST_DIR"
        fi

        # Copy background image to backgrounds directory
        cp "$BACKGROUND_SRC" "$BACKGROUND_DEST_PATH"

        # Set the background image
        gsettings set org.gnome.desktop.background picture-uri "file://$BACKGROUND_DEST_PATH"
        gsettings set org.gnome.desktop.background picture-uri-dark "file://$BACKGROUND_DEST_PATH"
        gsettings set org.gnome.desktop.background picture-options 'zoom'
    fi

    # Additional settings for window manager
    gext install just-perfection-desktop@just-perfection

    # Disable hot corners
    gsettings set org.gnome.desktop.interface enable-hot-corners false

    # Configure Dash to Dock settings
    gsettings set org.gnome.shell.extensions.dash-to-dock autohide false
    gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.5
    gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 24
    gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true
    gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
    gsettings set org.gnome.shell.extensions.dash-to-dock extend-height true
    gsettings set org.gnome.shell.extensions.dash-to-dock isolate-monitors true
    gsettings set org.gnome.shell.extensions.dash-to-dock isolate-workspaces true
    gsettings set org.gnome.shell.extensions.dash-to-dock multi-monitor true
    gsettings set org.gnome.shell.extensions.dash-to-dock running-indicator-style 'SQUARES'
    gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-always-in-the-edge true
    gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top false
    gsettings set org.gnome.shell.extensions.dash-to-dock show-show-apps-button true
    gsettings set org.gnome.shell.extensions.dash-to-dock custom-background-color true
    gsettings set org.gnome.shell.extensions.dash-to-dock background-color '#0f231c'

    status "GNOME and extensions configuration completed."
fi
