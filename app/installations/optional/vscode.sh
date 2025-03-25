install_if_not_present "visual-studio-code-bin" "yay -S visual-studio-code-bin --noconfirm --quiet"

if [ ! -d ~/.config/Code/User ]; then
    mkdir -p ~/.config/Code/User
    cp ./configs/code.json ~/.config/Code/User/settings.json
fi
