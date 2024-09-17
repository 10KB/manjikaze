status "Installing support for reading SMB network shares..."
sudo pacman -S smbclient gvfs gvfs-smb --noconfirm
pamac install nautilus-share manjaro-settings-samba --no-confirm
sudo mkdir -p /etc/samba
sudo touch /etc/samba/smb.conf