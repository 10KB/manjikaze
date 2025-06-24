# Alacritty requires this font to render properly.
if ! fc-list | grep -q "CaskaydiaMono Nerd Font"; then
    source "$MANJIKAZE_DIR/app/configuration/configure-font.sh"
fi

install_package "alacritty" repo

if [ ! -d ~/.config/alacritty ]; then
    mkdir -p ~/.config/alacritty
    cp "$MANJIKAZE_DIR/configs/alacritty.toml" ~/.config/alacritty/alacritty.toml
fi

# Pin Alacritty to dock and remove default terminal if using GNOME
if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
    status "Pinning Alacritty to dock and removing default terminal..."

    # Get current favorites
    current_favorites=$(gsettings get org.gnome.shell favorite-apps)

    # Remove the default terminal and trailing bracket
    new_favorites=$(echo "$current_favorites" | sed "s/'org.gnome.Terminal.desktop', //g" | sed "s/'gnome-terminal.desktop', //g" | sed 's/]$//')

    # Add Alacritty if not already in favorites
    if [[ "$new_favorites" != *"'org.gnome.Alacritty.desktop'"* ]] && [[ "$new_favorites" != *"'Alacritty.desktop'"* ]]; then
        # Check if we need to add a comma
        if [[ "$new_favorites" != *"," ]]; then
            new_favorites="${new_favorites}, "
        fi

        # Add Alacritty and closing bracket
        new_favorites="${new_favorites}'Alacritty.desktop']"
    else
        # Just add the closing bracket back
        new_favorites="${new_favorites}]"
    fi

    # Update favorites
    gsettings set org.gnome.shell favorite-apps "$new_favorites"
fi
