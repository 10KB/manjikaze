source "$MANJIKAZE_DIR/app/installations/optional/hyprland.sh"

if ! is_installed hyprland; then
    if gum confirm "Hyprland is not installed yet. Install it with launcher, bar and settings tools now?"; then
        install
    fi
    return
fi

status "Configuring the Hyprland desktop..."

# Copies a default config unless the user already has one; existing files are only replaced
# after confirmation, with a backup next to them.
hyprland_deploy() {
    local source="$1" destination="$2"

    mkdir -p "$(dirname "$destination")"
    if [[ ! -e $destination ]]; then
        cp "$source" "$destination"
        status "Created ${destination/#$HOME/\~}"
    elif ! cmp -s "$source" "$destination"; then
        if gum confirm "Replace ${destination/#$HOME/\~} with Manjikaze's version? A backup is kept." --default=false; then
            cp "$destination" "$destination.bak-$(date +%Y%m%d%H%M%S)"
            cp "$source" "$destination"
            status "Replaced ${destination/#$HOME/\~}"
        fi
    fi
}

# Hyprland: the user file loads Manjikaze's Lua defaults from this checkout, so updating
# Manjikaze updates them without touching personal overrides.
hypr_dir="$HOME/.config/hypr"
hyprland_lua="$hypr_dir/hyprland.lua"
hyprland_template=$(mktemp)
sed "s|__MANJIKAZE_DIR__|$MANJIKAZE_DIR|" "$MANJIKAZE_DIR/configs/hypr/hyprland.lua" >"$hyprland_template"

if [[ -f $hyprland_lua ]] && grep -q 'configs/hypr/bootstrap.lua' "$hyprland_lua"; then
    sed -i "s|dofile(\".*/configs/hypr/bootstrap.lua\")|dofile(\"$MANJIKAZE_DIR/configs/hypr/bootstrap.lua\")|" "$hyprland_lua"
else
    hyprland_deploy "$hyprland_template" "$hyprland_lua"
fi
rm -f "$hyprland_template"

for file in hypridle.conf hyprlock.conf hyprpaper.conf; do
    hyprland_deploy "$MANJIKAZE_DIR/configs/hypr/$file" "$hypr_dir/$file"
done

# Same wallpaper as the GNOME setup, used by hyprpaper and the lock screen.
mkdir -p "$HOME/.local/share/backgrounds"
if [[ ! -f $HOME/.local/share/backgrounds/manjikaze-background.jpg ]]; then
    cp "$MANJIKAZE_DIR/assets/background.jpg" "$HOME/.local/share/backgrounds/manjikaze-background.jpg"
fi

hyprland_deploy "$MANJIKAZE_DIR/configs/waybar/config.jsonc" "$HOME/.config/waybar/config.jsonc"
hyprland_deploy "$MANJIKAZE_DIR/configs/waybar/style.css" "$HOME/.config/waybar/style.css"
hyprland_deploy "$MANJIKAZE_DIR/configs/walker/config.toml" "$HOME/.config/walker/config.toml"
hyprland_deploy "$MANJIKAZE_DIR/configs/walker/themes/manjikaze/style.css" "$HOME/.config/walker/themes/manjikaze/style.css"
hyprland_deploy "$MANJIKAZE_DIR/configs/swaync/config.json" "$HOME/.config/swaync/config.json"
hyprland_deploy "$MANJIKAZE_DIR/configs/swaync/style.css" "$HOME/.config/swaync/style.css"
for file in "$MANJIKAZE_DIR"/configs/elephant/*.toml; do
    hyprland_deploy "$file" "$HOME/.config/elephant/$(basename "$file")"
done

# Session services. These units belong to Manjikaze, so they are always refreshed.
mkdir -p "$HOME/.config/systemd/user"
for unit in "$MANJIKAZE_DIR"/configs/systemd/user/*; do
    sed "s|__MANJIKAZE_DIR__|$MANJIKAZE_DIR|g" "$unit" >"$HOME/.config/systemd/user/$(basename "$unit")"
done
systemctl --user daemon-reload

# Environment for the uwsm-managed session (toolkits, cursor, NVIDIA detection, PATH).
uwsm_env="$HOME/.config/uwsm/env-hyprland"
mkdir -p "$(dirname "$uwsm_env")"
touch "$uwsm_env"
sed -i '/^# >>> manjikaze >>>$/,/^# <<< manjikaze <<<$/d' "$uwsm_env"
cat >>"$uwsm_env" <<EOF
# >>> manjikaze >>>
export MANJIKAZE_DIR="$MANJIKAZE_DIR"
. "\$MANJIKAZE_DIR/configs/uwsm/env-manjikaze"
# <<< manjikaze <<<
EOF

# Tray applets for network/VPN and bluetooth, only in Hyprland (GNOME has its own).
mkdir -p "$HOME/.config/autostart"
cat >"$HOME/.config/autostart/nm-applet.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=NetworkManager Applet
Exec=nm-applet --indicator
OnlyShowIn=Hyprland;
EOF
cat >"$HOME/.config/autostart/blueman.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Blueman Applet
Exec=blueman-applet
OnlyShowIn=Hyprland;
EOF

# Ulauncher is the GNOME launcher; Walker replaces it in Hyprland.
ulauncher_autostart="$HOME/.config/autostart/ulauncher.desktop"
if [[ -f $ulauncher_autostart ]] && ! grep -q 'ShowIn=' "$ulauncher_autostart"; then
    [[ -n $(tail -c1 "$ulauncher_autostart") ]] && echo >>"$ulauncher_autostart"
    echo "NotShowIn=Hyprland;" >>"$ulauncher_autostart"
fi

xdg-user-dirs-update >/dev/null 2>&1 || true

if lspci | grep -qi 'nvidia' && [[ $(sudo cat /sys/module/nvidia_drm/parameters/modeset 2>/dev/null) != "Y" ]]; then
    status "Warning: NVIDIA kernel modesetting is off. Hyprland needs nvidia_drm.modeset=1 on the kernel command line."
fi

current_session=$(hyprland_default_session)
default_session=$(gum choose "Hyprland" "GNOME" --header "Which desktop should start when you log in? (current: ${current_session:-unknown})" --selected "$([[ $current_session == hyprland* ]] && echo Hyprland || echo GNOME)")
case "$default_session" in
    Hyprland) hyprland_set_default_session hyprland-uwsm ;;
    GNOME) hyprland_set_default_session gnome ;;
esac

status "Hyprland is configured. Log out (or reboot) to start it; on the login screen you can"
status "still pick GNOME or 'Hyprland (uwsm-managed)' via the gear icon."
status "First steps: SUPER + SPACE opens apps, SUPER + K lists all shortcuts, SUPER + I opens settings,"
status "SUPER + P arranges displays (remembered per set of screens)."
