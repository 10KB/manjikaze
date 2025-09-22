#!/bin/bash

# This script installs Cursor by extracting an AppImage rather than using the AUR package (cursor-bin).
# Benefits of this approach:
# - Fixes mise-en-place integration in the terminal (the AppImage sandbox breaks this)
# - Makes updates more reliable and controlled through our system
# - Allows for better version detection and management
# - Minimizes sandbox-related permission issues

# User-Agent header to bypass Cloudflare's anti-bot checks
CURL_UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36"

get_cursor_download_url() {
    local html
    html=$(curl -s -L -H "User-Agent: $CURL_UA" "https://cursor.com/api/download")

    local download_url
    download_url=$(echo "$html" | grep -oE 'https://downloads\.cursor\.com/[^\"]+x86_64\.AppImage' | head -n 1)

    if [[ -z "$download_url" ]]; then
        status "Failed to find Cursor AppImage download URL."
        exit 1
    fi

    echo "$download_url"
}

get_cursor_installed_version() {
    local package_json=~/.local/share/cursor/usr/share/cursor/resources/app/package.json

    if [[ -f "$package_json" ]]; then
        local installed_version=$(jq -r '.version' "$package_json" 2>/dev/null)
        echo "$installed_version"
    else
        echo ""
    fi
}

download_cursor_appimage() {
    local download_url="$1"
    local output_file="${2:-/tmp/cursor.AppImage}"

    status "Downloading Cursor AppImage..."
    curl -s -L -H "User-Agent: $CURL_UA" "$download_url" -o "$output_file"
    chmod +x "$output_file"
}

install_cursor_from_appimage() {
    local appimage_path="${1:-/tmp/cursor.AppImage}"

    mkdir -p ~/.local/share/applications
    mkdir -p ~/.local/bin
    mkdir -p ~/.local/share/cursor

    status "Extracting AppImage..."
    cd /tmp
    "$appimage_path" --appimage-extract
    rm -f "$appimage_path"

    status "Installing Cursor..."
    rm -rf ~/.local/share/cursor/* || true
    mv /tmp/squashfs-root/* ~/.local/share/cursor/

    rm -f ~/.local/bin/cursor || true
    ln -sf ~/.local/share/cursor/usr/bin/cursor ~/.local/bin/cursor

    cat > ~/.local/share/applications/cursor.desktop << EOL
[Desktop Entry]
Name=Cursor
Comment=AI-first code editor
Exec=cursor
Icon=/home/$USER/.local/share/cursor/code.png
Type=Application
StartupNotify=true
Categories=Development;
EOL

    chmod +x ~/.local/share/applications/cursor.desktop
}

install_cursor() {
    status "Installing Cursor from extracted AppImage..."

    local download_url=$(get_cursor_download_url)
    download_cursor_appimage "$download_url"
    install_cursor_from_appimage

    status "Package 'cursor' installed successfully."
}

# If this script is being sourced, don't run the installation
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_cursor
fi
