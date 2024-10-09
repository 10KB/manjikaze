install_if_not_present "zellij" "sudo pacman -S zellij --noconfirm --noprogressbar --quiet"

mkdir -p ~/.config/zellij
if [ ! -f ~/.config/zellij/config.kdl ] || ! cmp -s ./configs/zellij.kdl ~/.config/zellij/config.kdl; then
    cp ./configs/zellij.kdl ~/.config/zellij/config.kdl
fi