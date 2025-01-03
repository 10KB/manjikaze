install_if_not_present "nodejs-lts-iron" "sudo pacman -S nodejs-lts-iron --noconfirm --noprogressbar --quiet"
install_if_not_present "npm" "sudo pacman -S npm --noconfirm --noprogressbar --quiet"
sudo npm --global --silent install yarn