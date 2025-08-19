#!/bin/bash
set -e

# Color formatting
FMT_RED=$(printf '\033[31m')
FMT_GREEN=$(printf '\033[32m')
FMT_YELLOW=$(printf '\033[33m')
FMT_BLUE=$(printf '\033[34m')
FMT_BOLD=$(printf '\033[1m')
FMT_RESET=$(printf '\033[0m')

# Installation directory
MANJIKAZE="${MANJIKAZE:-$HOME/.manjikaze}"

status() {
    printf "${FMT_BLUE}==>${FMT_BOLD} %s${FMT_RESET}\n" "$1"
}

# Check if Manjaro Linux
if [ ! -f /etc/manjaro-release ]; then
    echo "${FMT_RED}Error: This installer is only for Manjaro Linux${FMT_RESET}"
    exit 1
fi

# Install required packages
status "Installing required packages..."
sudo pacman -Sy archlinux-keyring manjaro-keyring
sudo pacman-key --init
sudo pacman-key --populate archlinux manjaro
sudo pacman -Syu --noconfirm --noprogressbar --quiet git gum

# Clone/update repository
if [ -d "$MANJIKAZE" ]; then
    status "Updating existing installation..."
    git -C "$MANJIKAZE" pull
else
    status "Cloning Manjikaze..."
    git clone https://github.com/10kb/manjikaze.git "$MANJIKAZE"
fi

# Create CLI command
status "Creating global CLI command..."
sudo tee /usr/local/bin/manjikaze > /dev/null << 'EOF'
#!/bin/bash
exec "$HOME/.manjikaze/bin/manjikaze" "$@"
EOF
sudo chmod +x /usr/local/bin/manjikaze

# Create desktop entry
status "Creating desktop entry..."
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/manjikaze.desktop" << EOF
[Desktop Entry]
Name=Manjikaze
Comment=10KB Manjaro Development Environment
Exec=manjikaze
Icon=${MANJIKAZE}/assets/icon.png
Terminal=true
Type=Application
Categories=Development;System;
EOF

# Success message
cat << EOF

${FMT_GREEN}Manjikaze has been successfully installed!${FMT_RESET}

You can now:
1. Run ${FMT_BOLD}manjikaze${FMT_RESET} from anywhere in your terminal
2. Launch it from your applications menu

For documentation, visit:
https://github.com/10kb/manjikaze/tree/main/docs

EOF
