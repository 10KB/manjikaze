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
    local release_track="$1"
    local api_url="https://cursor.com/api/download?platform=linux-x64"

    if [[ "$release_track" == "nightly" ]]; then
        api_url="${api_url}&releaseTrack=latest&appName=cursor-nightly"
    else
        api_url="${api_url}&releaseTrack=$release_track"
    fi

    local download_url=$(curl -s -L -H "User-Agent: $CURL_UA" "$api_url" | jq -r '.downloadUrl')

    if [[ -z "$download_url" ]]; then
        status "Failed to get Cursor download URL."
        exit 1
    fi

    echo "$download_url"
}

get_cursor_version_from_dir() {
    local install_dir="$1"

    local package_json=""
    if [[ -f "$install_dir/usr/share/cursor-nightly/resources/app/package.json" ]]; then
        package_json="$install_dir/usr/share/cursor-nightly/resources/app/package.json"
    elif [[ -f "$install_dir/usr/share/cursor/resources/app/package.json" ]]; then
        package_json="$install_dir/usr/share/cursor/resources/app/package.json"
    fi

    if [[ -n "$package_json" ]]; then
        jq -r '.version' "$package_json" 2>/dev/null
    else
        echo ""
    fi
}

get_cursor_installed_version() {
    get_cursor_version_from_dir ~/.local/share/cursor
}

download_cursor_appimage() {
    local download_url="$1"
    local output_file="${2:-/tmp/cursor.AppImage}"

    status "Downloading Cursor from: $download_url"
    curl -s -L -H "User-Agent: $CURL_UA" "$download_url" -o "$output_file"
    chmod +x "$output_file"
}

install_cursor_to_dir() {
    local appimage_path="$1"
    local install_dir="$2"
    local bin_name="$3"
    local app_name="$4"

    mkdir -p ~/.local/share/applications
    mkdir -p ~/.local/bin
    mkdir -p "$install_dir"

    status "Extracting AppImage..."
    cd /tmp
    rm -rf /tmp/squashfs-root
    "$appimage_path" --appimage-extract >/dev/null 2>&1
    rm -f "$appimage_path"

    status "Installing $app_name..."
    rm -rf "$install_dir"/* || true
    mv /tmp/squashfs-root/* "$install_dir"/
    rm -rf /tmp/squashfs-root

    rm -f ~/.local/bin/"$bin_name" || true
    if [[ -f "$install_dir/usr/bin/cursor-nightly" ]]; then
        ln -sf "$install_dir/usr/bin/cursor-nightly" ~/.local/bin/"$bin_name"
    else
        ln -sf "$install_dir/usr/bin/cursor" ~/.local/bin/"$bin_name"
    fi

    local icon_path=""
    if [[ -f "$install_dir/cursor-nightly.png" ]]; then
        icon_path="$install_dir/cursor-nightly.png"
    else
        icon_path="$install_dir/code.png"
    fi

    cat > ~/.local/share/applications/"$bin_name".desktop << EOL
[Desktop Entry]
Name=$app_name
Comment=AI-first code editor
Exec=$bin_name
Icon=$icon_path
Type=Application
StartupNotify=true
Categories=Development;
EOL

    chmod +x ~/.local/share/applications/"$bin_name".desktop

    local installed_version=$(get_cursor_version_from_dir "$install_dir")
    status "Package '$bin_name' version $installed_version installed successfully."
}

install_cursor_from_appimage() {
    local appimage_path="${1:-/tmp/cursor.AppImage}"
    install_cursor_to_dir "$appimage_path" ~/.local/share/cursor "cursor" "Cursor"
}

install() {
    local release_track=$(get_cursor_release_track)

    if [[ "$release_track" == "stable+nightly" ]]; then
        status "Installing Cursor (stable) from extracted AppImage..."
        local stable_url=$(get_cursor_download_url "stable")
        download_cursor_appimage "$stable_url" /tmp/cursor-stable.AppImage
        install_cursor_to_dir /tmp/cursor-stable.AppImage ~/.local/share/cursor "cursor" "Cursor"

        status "Installing Cursor (nightly) from extracted AppImage..."
        local nightly_url=$(get_cursor_download_url "nightly")
        download_cursor_appimage "$nightly_url" /tmp/cursor-nightly.AppImage
        install_cursor_to_dir /tmp/cursor-nightly.AppImage ~/.local/share/cursor-nightly "cursor-nightly" "Cursor Nightly"
    else
        status "Installing Cursor ($release_track) from extracted AppImage..."
        local download_url=$(get_cursor_download_url "$release_track")
        download_cursor_appimage "$download_url"
        install_cursor_from_appimage
    fi
}

uninstall() {
    status "Uninstalling Cursor..."
    rm -rf ~/.local/share/cursor
    rm -rf ~/.local/share/cursor-nightly
    rm -f ~/.local/bin/cursor
    rm -f ~/.local/bin/cursor-nightly
    rm -f ~/.local/share/applications/cursor.desktop
    rm -f ~/.local/share/applications/cursor-nightly.desktop
    status "Package 'cursor' uninstalled successfully."
}
