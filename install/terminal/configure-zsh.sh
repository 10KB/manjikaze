if [ ! -d ~/.oh-my-zsh ]; then
    status "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    # Change theme to Agnoster
    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' ~/.zshrc

    # Enable auto updates
    sed -i "s/# zstyle ':omz:update' mode auto/zstyle ':omz:update' mode auto/" ~/.zshrc

    # Enable plugins
    sed -i 's/plugins=(git)/plugins=(archlinux aws docker docker-compose git git-flow zoxide)/' ~/.zshrc

    # Hide user@host
    echo 'export DEFAULT_USER=rolandboon' >> ~/.zshrc

    # Source .zshrc to apply changes
    source ~/.zshrc
fi