status "Updating installed packages..."
disable_sleep

sudo pacman -Syu --noconfirm --noprogressbar --quiet
yay -Syu --noconfirm --noprogressbar --quiet

enable_sleep
