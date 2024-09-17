status "Installing Cursor code editor..."
yay -S cursor-bin --noconfirm

if [ ! -d ~/.config/Code\ -\ OSS/User ]; then
    mkdir -p ~/.config/Code\ -\ OSS/User
    cp ./configs/code.json ~/.config/Code\ -\ OSS/User/settings.json
fi

cursor --install-extension EditorConfig.EditorConfig
cursor --install-extension dbaeumer.vscode-eslint
cursor --install-extension esbenp.prettier-vscode
cursor --install-extension eamodio.gitlens
