set -e

# Ensure computer doesn't go to sleep or lock while installing
gsettings set org.gnome.desktop.screensaver lock-enabled false
gsettings set org.gnome.desktop.session idle-delay 0

# Install initial required tools
for installer in ./install/terminal/required/*.sh; do source $installer; done

# Choose from optional apps
source ./install/choices.sh

# Install terminal tools
source ./install/terminal.sh

# Install desktop tools
source ./install/desktop.sh

# Revert to normal idle and lock settings
gsettings set org.gnome.desktop.screensaver lock-enabled true
gsettings set org.gnome.desktop.session idle-delay 300
