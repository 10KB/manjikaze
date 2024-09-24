status "Installing support for reading SMB network shares..."
sudo pacman -S smbclient gvfs gvfs-smb cifs-utils --noconfirm --noprogressbar --quiet
yay -S wsdd --noconfirm --noprogressbar --quiet
pamac install nautilus-share manjaro-settings-samba --no-confirm
