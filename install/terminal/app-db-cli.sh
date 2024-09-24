status "Installing Postgres and MySQL clients..."
sudo pacman -S postgresql-client --noconfirm --noprogressbar --quiet
yay -S mysql-clients --noconfirm --noprogressbar --quiet