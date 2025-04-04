install_if_not_present "smbclient" "sudo pacman -S smbclient --noconfirm --noprogressbar --quiet"
install_if_not_present "gvfs" "sudo pacman -S gvfs --noconfirm --noprogressbar --quiet"
install_if_not_present "gvfs-smb" "sudo pacman -S gvfs-smb --noconfirm --noprogressbar --quiet"
install_if_not_present "cifs-utils" "sudo pacman -S cifs-utils --noconfirm --noprogressbar --quiet"
install_if_not_present "wsdd" "yay -S wsdd --noconfirm --noprogressbar --quiet"
install_if_not_present "nautilus-share" "pamac install nautilus-share manjaro-settings-samba --no-confirm"