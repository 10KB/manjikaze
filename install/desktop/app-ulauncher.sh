status "Installing Ulauncher launcher..."
yay -S ulauncher --noconfirm --noprogressbar --quiet

mkdir -p ~/.config/autostart/
cp ./configs/ulauncher.desktop ~/.config/autostart/
sleep 2
cp ./configs/ulauncher.json ~/.config/ulauncher/settings.json
