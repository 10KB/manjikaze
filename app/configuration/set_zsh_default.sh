#!/bin/bash

set_zsh_as_default() {
    status "Setting zsh as default shell"

    # Check if zsh is installed
    if ! which zsh > /dev/null; then
        status "Installing zsh"
        sudo pacman -S zsh --noconfirm --noprogressbar --quiet
    fi

    # Set zsh as default shell
    if [ "$SHELL" != "/usr/bin/zsh" ]; then
        status "Changing default shell to zsh"
        chsh -s /usr/bin/zsh
        
        # Confirm with user using gum
        if gum confirm "Shell change requires a logout/login to take effect. Log out now?"; then
            status "Logging out..."
            pkill -KILL -u "$USER"
        else
            status "Please log out and back in to use zsh as your default shell"
        fi
    else
        status "Zsh is already your default shell"
    fi
}