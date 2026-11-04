source "$MANJIKAZE_DIR/app/installations/optional/hyprland.sh"

if ! is_installed hyprland; then
    if gum confirm "Hyprland is not installed yet. Install it now?"; then
        install
    fi
    return
fi

status "Configuring the Hyprland desktop..."

# Packages added to Manjikaze after Hyprland was first installed.
hyprland_install_packages || return

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
first_configuration=true
[[ -f $hyprland_lua ]] && first_configuration=false
hyprland_template=$(mktemp)
sed "s|__MANJIKAZE_DIR__|$MANJIKAZE_DIR|" "$MANJIKAZE_DIR/configs/hypr/hyprland.lua" >"$hyprland_template"

if [[ -f $hyprland_lua ]] && grep -q 'configs/hypr/bootstrap.lua' "$hyprland_lua"; then
    sed -i "s|dofile(\".*/configs/hypr/bootstrap.lua\")|dofile(\"$MANJIKAZE_DIR/configs/hypr/bootstrap.lua\")|" "$hyprland_lua"
else
    hyprland_deploy "$hyprland_template" "$hyprland_lua"
fi
rm -f "$hyprland_template"

hyprland_deploy "$MANJIKAZE_DIR/configs/walker/config.toml" "$HOME/.config/walker/config.toml"
hyprland_deploy "$MANJIKAZE_DIR/configs/walker/themes/manjikaze/style.css" "$HOME/.config/walker/themes/manjikaze/style.css"
for file in "$MANJIKAZE_DIR"/configs/elephant/*.toml; do
    hyprland_deploy "$file" "$HOME/.config/elephant/$(basename "$file")"
done

# Session services. These units belong to Manjikaze, so they are always refreshed.
mkdir -p "$HOME/.config/systemd/user"
for unit in "$MANJIKAZE_DIR"/configs/systemd/user/*; do
    sed "s|__MANJIKAZE_DIR__|$MANJIKAZE_DIR|g" "$unit" >"$HOME/.config/systemd/user/$(basename "$unit")"
done
systemctl --user daemon-reload
if [[ $XDG_CURRENT_DESKTOP == *Hyprland* ]]; then
    # Elephant and Walker read their configuration only at start.
    systemctl --user try-restart manjikaze-elephant.service manjikaze-walker.service || true
    # Starts the services added since login.
    systemctl --user start manjikaze-hyprland.target || true
fi

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

# Ulauncher is the GNOME launcher; Walker replaces it in Hyprland.
ulauncher_autostart="$HOME/.config/autostart/ulauncher.desktop"
if [[ -f $ulauncher_autostart ]] && ! grep -q 'ShowIn=' "$ulauncher_autostart"; then
    [[ -n $(tail -c1 "$ulauncher_autostart") ]] && echo >>"$ulauncher_autostart"
    echo "NotShowIn=Hyprland;" >>"$ulauncher_autostart"
fi

# nvidia_drm only exists while the NVIDIA driver is loaded; nouveau and Intel-only setups skip this.
modeset_file=/sys/module/nvidia_drm/parameters/modeset
if [[ -r $modeset_file && $(<"$modeset_file") != "Y" ]]; then
    status "Warning: NVIDIA kernel modesetting is off. Hyprland needs nvidia_drm.modeset=1 on the kernel command line."
fi

# The first configuration preselects Hyprland; later runs preselect the current default.
current_session=$(hyprland_default_session)
selected_session=Hyprland
if [[ $first_configuration == false && $current_session != hyprland* ]]; then
    selected_session=GNOME
fi
default_session=$(gum choose "Hyprland" "GNOME" --header "Which desktop should start when you log in? (current: ${current_session:-unknown})" --selected "$selected_session") || true
case "$default_session" in
    Hyprland) hyprland_set_default_session hyprland-uwsm ;;
    GNOME) hyprland_set_default_session gnome ;;
esac
status "Default desktop: $(hyprland_default_session)."

if grep -qi '^AutomaticLoginEnable=true' /etc/gdm/custom.conf 2>/dev/null; then
    status "Automatic login is on: after a reboot the default desktop starts without a login screen."
fi
status "Hyprland is configured. Log out (or reboot) to start it. To pick a desktop on the login screen,"
status "click your name and use the gear icon next to 'Sign In'. With a YubiKey inserted the password step"
status "is skipped and so is the gear: remove the key first."
