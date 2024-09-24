status "Installing Node.js runtime..."
sudo pacman -S nodejs-lts-iron npm --noconfirm --noprogressbar --quiet
sudo npm --global --silent install yarn