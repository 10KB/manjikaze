install_if_not_present "vim" "pacman -S vim --noconfirm --noprogressbar --quiet"

if [ ! -f "$HOME/.vimrc" ]; then
    cp /usr/share/vim/vimfiles/vimrc_example.vim "$HOME/.vimrc" 2>/dev/null || true
fi