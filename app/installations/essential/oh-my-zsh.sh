configure_oh_my_zsh() {
    install_package "zsh" repo

    if [ "$SHELL" != "/usr/bin/zsh" ]; then
        status "Setting zsh as default shell..."
        chsh -s /usr/bin/zsh
    fi

    if [ -d ~/.oh-my-zsh ]; then
        status "Oh My Zsh is already installed."
        return 0
    fi

    status "Installing Oh My Zsh..."
    if ! sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
        status "Failed to install Oh My Zsh."
        return 1
    fi

    # Change theme to Agnoster
    if ! sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' ~/.zshrc; then
        status "Failed to change Oh My Zsh theme."
        return 1
    fi

    # Enable auto updates
    if ! sed -i "s/# zstyle ':omz:update' mode auto/zstyle ':omz:update' mode auto/" ~/.zshrc; then
        status "Failed to enable Oh My Zsh auto updates."
        return 1
    fi

    # Enable plugins
    if ! sed -i 's/plugins=(git)/plugins=(archlinux aws docker docker-compose git git-flow zoxide)/' ~/.zshrc; then
        status "Failed to enable Oh My Zsh plugins."
        return 1
    fi

    # Hide user@host
    if ! echo 'export DEFAULT_USER=rolandboon' >> ~/.zshrc; then
        status "Failed to set DEFAULT_USER in .zshrc."
        return 1
    fi

    # Source .zshrc to apply changes
    if ! source ~/.zshrc; then
        status "Failed to source .zshrc."
        return 1
    fi

    status "Oh My Zsh configuration completed successfully."
}

configure_oh_my_zsh