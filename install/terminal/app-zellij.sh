status "Installing Zellij terminal multiplexer..."
sudo pacman -S zellij --noconfirm --noprogressbar --quiet

mkdir -p ~/.config/zellij/themes
curl -sL https://raw.githubusercontent.com/zellij-org/zellij/main/themes/catppuccin_macchiato.yaml -o ~/.config/zellij/themes/catppuccin_macchiato.yaml
cp ./configs/zellij.kdl ~/.config/zellij/config.kdl