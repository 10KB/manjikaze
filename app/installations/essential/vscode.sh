install_if_not_present "code" "sudo pacman -S code --noconfirm --noprogressbar --quiet"

if [ ! -d ~/.config/Code\ -\ OSS/User ]; then
    mkdir -p ~/.config/Code\ -\ OSS/User
    cp ./configs/code.json ~/.config/Code\ -\ OSS/User/settings.json
fi