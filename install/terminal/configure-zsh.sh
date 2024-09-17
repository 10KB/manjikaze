if [ ! -d ~/.oh-my-zsh ]; then
    status "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    # Change theme to Agnoster
    sed -i 's/robbyrussell/agnoster/g' ~/.zshrc

    # Enable auto updates
    sed -i "s/# zstyle ':omz:update' mode auto/zstyle ':omz:update' mode auto/g" ~/.zshrc

    # Enable plugins
    sed -i 's/plugins=(git)/plugins=(archlinux aws docker docker-compose git git-flow zoxide)/g' ~/.zshrc

    # Hide user@host
    echo 'export DEFAULT_USER=rolandboon' >> ~/.zshrc
fi