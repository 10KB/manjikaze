status "Removing preinstalled apps..."

# List of apps to remove
apps=(
    "gnome-contacts"
    "gnome-chess"
    "gnome-mines"
    "gnome-maps"
    "gnome-tour"
    "gnome-weather"
    "endeavour"
    "fragments"
    "totem"
    "malcontent"
    "quadrapassel"
    "iagno"
    "lollypop"
)

for app in "${apps[@]}"; do
    if pacman -Qi "$app" &> /dev/null; then
        pamac remove "$app" --no-confirm
    fi
done