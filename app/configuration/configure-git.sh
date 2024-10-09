configure_git() {
    setup_git=$(gum confirm "Do you want to configure global Git settings?" --affirmative "Yes" --negative "No" --default=false && echo "true" || echo "false")

    if [[ $setup_git == "true" ]]; then
        status "Configuring global Git settings..."
        
        git config --global alias.co checkout
        git config --global alias.br branch
        git config --global alias.ci commit
        git config --global alias.st status
        git config --global pull.rebase true

        status "Global Git configuration completed."
    fi
}
