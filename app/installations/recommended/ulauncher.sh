install_package "ulauncher" aur

mkdir -p ~/.config/autostart/
if [ ! -f ~/.config/autostart/ulauncher.desktop ]; then
    cp ./configs/ulauncher.desktop ~/.config/autostart/
fi

mkdir -p ~/.config/ulauncher/
if [ ! -f ~/.config/ulauncher/settings.json ]; then
    cp ./configs/ulauncher.json ~/.config/ulauncher/settings.json
fi
