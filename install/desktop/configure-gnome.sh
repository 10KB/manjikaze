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
yay -S extension-manager --noconfirm
yay -S gnome-extensions-cli --noconfirm

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

# Additional settings for window manager
gext install just-perfection-desktop@just-perfection

# Disable hot corners
gsettings set org.gnome.desktop.interface enable-hot-corners false

## Configure Dash to Dock settings
gsettings set org.gnome.shell.extensions.dash-to-dock autohide false
gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.8
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 24
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height true
gsettings set org.gnome.shell.extensions.dash-to-dock isolate-monitors true
gsettings set org.gnome.shell.extensions.dash-to-dock isolate-workspaces true
gsettings set org.gnome.shell.extensions.dash-to-dock multi-monitor true
gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-always-in-the-edge true
gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top false
gsettings set org.gnome.shell.extensions.dash-to-dock show-show-apps-button true
