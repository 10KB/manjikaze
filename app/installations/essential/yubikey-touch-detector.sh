install_if_not_present "yubikey-touch-detector" "yay -S --noconfirm --noprogressbar --quiet yubikey-touch-detector"
install_if_not_present "libnotify" "sudo pacman -S --noconfirm --noprogressbar --quiet libnotify"

mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/yubikey-touch-detector"

cat > "${XDG_CONFIG_HOME:-$HOME/.config}/yubikey-touch-detector/service.conf" << EOF
YUBIKEY_TOUCH_DETECTOR_VERBOSE=false
YUBIKEY_TOUCH_DETECTOR_LIBNOTIFY=true
YUBIKEY_TOUCH_DETECTOR_STDOUT=false
YUBIKEY_TOUCH_DETECTOR_NOSOCKET=false
EOF

systemctl --user daemon-reload
systemctl --user enable --now yubikey-touch-detector.service