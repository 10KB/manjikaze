install_package "code" repo

if [ ! -d ~/.config/Code\ -\ OSS/User ]; then
    mkdir -p ~/.config/Code\ -\ OSS/User
    cp ./configs/code.json ~/.config/Code\ -\ OSS/User/settings.json
fi