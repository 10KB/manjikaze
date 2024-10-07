status "Installing Cursor code editor..."
yay -S cursor-bin --noconfirm --noprogressbar --quiet

if [ ! -d ~/.config/Code\ -\ OSS/User ]; then
    mkdir -p ~/.config/Code\ -\ OSS/User
    cp ./configs/code.json ~/.config/Code\ -\ OSS/User/settings.json
fi
