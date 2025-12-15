#!/bin/bash

status() {
    gum log --time TimeOnly --structured --level info "$1"
}

get_version() {
    git -C "$MANJIKAZE_DIR" describe --tags 2>/dev/null || echo "dev"
}

is_installed() {
    pacman -Qi "$1" &> /dev/null
}

disable_sleep() {
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
        status "Disabling screen lock and sleep during installation..."
        gsettings set org.gnome.desktop.screensaver lock-enabled false
        gsettings set org.gnome.desktop.session idle-delay 0
    fi
}

enable_sleep() {
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
        status "Re-enabling screen lock and sleep..."
        gsettings set org.gnome.desktop.screensaver lock-enabled true
        gsettings set org.gnome.desktop.session idle-delay 300
    fi
}

activate_zsh_plugin() {
    local plugin="$1"
    local zshrc="$HOME/.zshrc"
    local plugins_line=$(grep -E "^plugins=\([^)]*\)" "$zshrc")

    if [ -z "$plugins_line" ]; then
        status "No plugins line found in .zshrc. Skipping oh-my-zsh plugin activation."
        return 1
    fi

    if [[ "$plugins_line" == *"$plugin"* ]]; then
        status "Plugin '$plugin' is already activated."
        return 0
    fi

    local plugins_content=$(echo "$plugins_line" | sed -E 's/^plugins=\((.*)\)/\1/')
    local new_plugins_content

    if [ -z "$plugins_content" ]; then
        new_plugins_content="$plugin"
    else
        new_plugins_content="$plugins_content $plugin"
    fi

    sed -i "s/^plugins=([^)]*)$/plugins=($new_plugins_content)/" "$zshrc"

    status "Activated oh-my-zsh plugin: $plugin"
    return 0
}

deactivate_zsh_plugin() {
    local plugin="$1"
    local zshrc="$HOME/.zshrc"
    local plugins_line=$(grep -E "^plugins=\([^)]*\)" "$zshrc")

    if [ -z "$plugins_line" ]; then
        status "No plugins line found in .zshrc. Skipping oh-my-zsh plugin deactivation."
        return 1
    fi

    if [[ "$plugins_line" != *"$plugin"* ]]; then
        status "Plugin '$plugin' is not activated."
        return 0
    fi

    # Handle various cases where plugin might be in the middle, start, or end of the list
    sed -i -E "s/plugins=\(([^)]*)$plugin([^)]*)\)/plugins=(\1\2)/" "$zshrc"

    # Clean up any duplicate spaces
    sed -i -E "s/plugins=\(([^)]*) {2,}([^)]*)\)/plugins=(\1 \2)/" "$zshrc"

    # Clean up leading/trailing spaces in plugin list
    sed -i -E "s/plugins=\( (.*)\)/plugins=(\1)/" "$zshrc"
    sed -i -E "s/plugins=\((.*) \)/plugins=(\1)/" "$zshrc"

    status "Deactivated oh-my-zsh plugin: $plugin"
    return 0
}

install_package() {
    local package=$1
    local type=${2:-repo} # Default to repo

    if is_installed "$package"; then
        status "Package '$package' is already installed. Skipping."
        return 0
    fi

    set +e
    local output
    if [[ "$type" == "aur" ]]; then
        status "Installing AUR package $package..."
        # Ensure system tools use system Python for building AUR packages
        output=$(PATH=/usr/bin:$PATH yay -S "$package" --noconfirm --noprogressbar --quiet 2>&1)
    else
        status "Installing repository package $package..."
        output=$(sudo pacman -S "$package" --noconfirm --noprogressbar --quiet 2>&1)
    fi
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        status "Failed to install $package"

        if ! gum confirm "Continue with installation of other packages?"; then
            return 2 # Special code to indicate user-requested abort
        fi

        status "Continuing installation process..."
        return 1 # Indicate failure but script continues
    else
        status "Package '$package' installed successfully."
    fi
    set -e
}

uninstall_package() {
    local package=$1
    local type=${2:-repo} # Default to repo

    if ! is_installed "$package"; then
        status "Package '$package' is not installed. Skipping."
        return 0
    fi

    set +e
    local output
    if [[ "$type" == "aur" ]]; then
        status "Uninstalling AUR package $package..."
        output=$(yay -R "$package" --noconfirm --noprogressbar 2>&1)
    else
        status "Uninstalling repository package $package..."
        output=$(sudo pacman -R "$package" --noconfirm --noprogressbar --quiet 2>&1)
    fi
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        status "Failed to uninstall $package"

        if ! gum confirm "Continue with uninstallation of other packages?"; then
            return 2 # Special code to indicate user-requested abort
        fi

        status "Continuing uninstallation process..."
        return 1 # Indicate failure but script continues
    else
        status "Package '$package' uninstalled successfully."
    fi
    set -e
}

