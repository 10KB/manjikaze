update_installed_apps() {
    status "Updating installed packages..."
    sudo pacman -Syu --noconfirm --noprogressbar --quiet
    yay -Syu --noconfirm --noprogressbar --quiet
}