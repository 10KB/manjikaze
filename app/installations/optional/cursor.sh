#!/bin/bash

# This script installs Cursor.
# - Stable builds are installed from the official signed Debian repository (verified GPG signature).
# - Nightly builds are installed from AppImage (unsigned, use at own risk).

# User-Agent header to bypass Cloudflare's anti-bot checks on cursor.com API
CURL_UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36"

# Constants
CURSOR_GPG_KEY_URL="https://downloads.cursor.com/keys/anysphere.asc"
CURSOR_KEY_FINGERPRINT="380FF4BCDC34A4BD92A3565342A1772E62E492D6"
CURSOR_REPO_BASE="https://downloads.cursor.com/aptrepo"
CURSOR_REPO_DIST="stable"
CURSOR_REPO_ARCH="binary-amd64"
CONFIG_FILE="$HOME/.config/manjikaze/cursor_track"

# --- Track Management ---

get_cursor_release_track() {
    if [[ -f "$CONFIG_FILE" ]]; then
        cat "$CONFIG_FILE"
    else
        echo "stable"
    fi
}

set_cursor_release_track() {
    local track="$1"
    mkdir -p "$(dirname "$CONFIG_FILE")"
    echo "$track" > "$CONFIG_FILE"
}

# --- Version Helpers ---

get_cursor_version_from_dir() {
    local install_dir="$1"
    local package_json=""

    if [[ -f "$install_dir/resources/app/package.json" ]]; then
        package_json="$install_dir/resources/app/package.json"
    elif [[ -f "$install_dir/usr/share/cursor/resources/app/package.json" ]]; then
        package_json="$install_dir/usr/share/cursor/resources/app/package.json"
    fi

    if [[ -n "$package_json" ]]; then
        jq -r '.version' "$package_json" 2>/dev/null
    fi
}

get_cursor_installed_version() {
    get_cursor_version_from_dir "$HOME/.local/share/cursor"
}

get_cursor_installed_nightly_version() {
    get_cursor_version_from_dir "$HOME/.local/share/cursor-nightly"
}

get_cursor_installed_version_display() {
    local track=$(get_cursor_release_track)
    local parts=()

    if [[ "$track" == "nightly" || "$track" == "stable+nightly" ]]; then
        local nv=$(get_cursor_installed_nightly_version)
        if [[ -n "$nv" ]]; then parts+=("Nightly: $nv"); fi
    fi
    if [[ "$track" != "nightly" ]]; then
        local sv=$(get_cursor_installed_version)
        if [[ -n "$sv" ]]; then parts+=("Stable: $sv"); fi
    fi

    local IFS=", "
    echo "${parts[*]}"
}

# Fetches the latest stable version from the repository metadata.
# This is a lightweight check (no GPG verification); full verification happens during install.
get_cursor_latest_stable_version() {
    local temp_file=$(mktemp)
    local packages_url="${CURSOR_REPO_BASE}/dists/${CURSOR_REPO_DIST}/main/${CURSOR_REPO_ARCH}/Packages.gz"

    if ! curl -fsSL "$packages_url" -o "$temp_file" 2>/dev/null; then
        rm -f "$temp_file"
        return
    fi

    gunzip -c "$temp_file" 2>/dev/null | awk '
        /^Package: cursor$/ { found=1; next }
        found && /^Version: / { sub(/^Version: /, ""); print; exit }
        /^$/ { found=0 }
    ' || true

    rm -f "$temp_file"
}

# --- Installation Methods ---

# Runs in a subshell to isolate cd and guarantee cleanup via EXIT trap.
install_stable_signed() (
    set -e
    local temp_dir=$(mktemp -d)
    trap "rm -rf '$temp_dir'" EXIT

    local gpg_home="$temp_dir/gpghome"
    mkdir -m 700 "$gpg_home"

    local key_cache_dir="$HOME/.cache/manjikaze/keys"
    mkdir -p "$key_cache_dir"
    local key_file="$key_cache_dir/cursor_anysphere.asc"

    if [[ ! -f "$key_file" ]]; then
        status "Downloading Cursor GPG key..."
        if ! curl -fsSL "$CURSOR_GPG_KEY_URL" -o "$key_file"; then
            status "Error: Failed to download GPG key."
            exit 1
        fi
    fi

    status "Verifying GPG key and repository signature..."
    gpg --homedir "$gpg_home" --quiet --import "$key_file" 2>/dev/null

    local imported_fp=$(gpg --homedir "$gpg_home" --with-colons --fingerprint 2>/dev/null \
        | awk -F: '/^fpr:/{print $10; exit}')
    if [[ "$imported_fp" != "$CURSOR_KEY_FINGERPRINT" ]]; then
        status "Error: GPG key fingerprint mismatch! Expected $CURSOR_KEY_FINGERPRINT, got $imported_fp"
        rm -f "$key_file"
        exit 1
    fi

    local inrelease_file="$temp_dir/InRelease"
    if ! curl -fsSL "${CURSOR_REPO_BASE}/dists/${CURSOR_REPO_DIST}/InRelease" -o "$inrelease_file"; then
        status "Error: Failed to download repository metadata."
        exit 1
    fi

    if ! gpg --homedir "$gpg_home" --verify "$inrelease_file" 2>/dev/null; then
        status "Error: Repository signature verification failed!"
        exit 1
    fi

    local packages_path="main/${CURSOR_REPO_ARCH}/Packages.gz"
    local packages_sha256=$(awk -v path="$packages_path" '
        /^SHA256:/ { in_sha256 = 1; next }
        /^[A-Z][a-zA-Z0-9-]*:/ { in_sha256 = 0 }
        in_sha256 && $3 == path { print $1; exit }
    ' "$inrelease_file")

    if [[ -z "$packages_sha256" ]]; then
        status "Error: Could not find package index hash in InRelease."
        exit 1
    fi

    status "Fetching package index..."
    local packages_file="$temp_dir/Packages.gz"
    if ! curl -fsSL "${CURSOR_REPO_BASE}/dists/${CURSOR_REPO_DIST}/${packages_path}" -o "$packages_file"; then
        status "Error: Failed to download package index."
        exit 1
    fi

    local actual_sha256=$(sha256sum "$packages_file" | awk '{print $1}')
    if [[ "$actual_sha256" != "$packages_sha256" ]]; then
        status "Error: Package index checksum mismatch."
        exit 1
    fi

    local parsed_info=$(gunzip -c "$packages_file" | awk '
        /^Package: cursor$/ { found=1; next }
        found && /^Filename: / { sub(/^Filename: /, ""); filename=$0 }
        found && /^SHA256: / { sub(/^SHA256: /, ""); sha=$0 }
        found && /^Version: / { sub(/^Version: /, ""); ver=$0 }
        found && /^$/ { exit }
        END { if (filename) print filename "|" sha "|" ver }
    ')
    IFS='|' read -r deb_filename deb_sha256 deb_version <<< "$parsed_info"

    if [[ -z "$deb_filename" ]]; then
        status "Error: Package 'cursor' not found in repository index."
        exit 1
    fi

    status "Downloading Cursor $deb_version..."
    local deb_file="$temp_dir/cursor.deb"
    if ! curl -fsSL "${CURSOR_REPO_BASE}/${deb_filename}" -o "$deb_file"; then
        status "Error: Failed to download Cursor package."
        exit 1
    fi

    local actual_deb_sha=$(sha256sum "$deb_file" | awk '{print $1}')
    if [[ "$actual_deb_sha" != "$deb_sha256" ]]; then
        status "Error: .deb checksum mismatch."
        exit 1
    fi

    status "Extracting..."
    local extract_dir="$temp_dir/extract"
    mkdir -p "$extract_dir"

    cd "$temp_dir"
    ar x cursor.deb
    tar -xf data.tar.* -C "$extract_dir"

    local extracted_root=""
    if [[ -d "$extract_dir/opt/Cursor" ]]; then
        extracted_root="$extract_dir/opt/Cursor"
    elif [[ -d "$extract_dir/usr/share/cursor" ]]; then
        extracted_root="$extract_dir/usr/share/cursor"
    else
        status "Error: Could not locate Cursor files in extracted .deb package."
        exit 1
    fi

    local final_dest="$HOME/.local/share/cursor"
    rm -rf "$final_dest"
    mkdir -p "$(dirname "$final_dest")"
    mv "$extracted_root" "$final_dest"

    mkdir -p "$HOME/.local/bin"
    rm -f "$HOME/.local/bin/cursor"
    ln -sf "$final_dest/cursor" "$HOME/.local/bin/cursor"

    mkdir -p "$HOME/.local/share/applications"
    cat > "$HOME/.local/share/applications/cursor.desktop" << EOL
[Desktop Entry]
Name=Cursor
Comment=AI-first code editor
Exec=$HOME/.local/bin/cursor
Icon=$final_dest/resources/app/resources/linux/code.png
Type=Application
StartupNotify=true
Categories=Development;
EOL
    chmod +x "$HOME/.local/share/applications/cursor.desktop"

    status "Cursor Stable $deb_version installed successfully."
)

# Runs in a subshell to isolate cd and guarantee cleanup via EXIT trap.
install_nightly_appimage() (
    set -e
    local temp_file=$(mktemp)
    trap "rm -f '$temp_file'; rm -rf /tmp/squashfs-root" EXIT

    status "WARNING: Nightly builds are unsigned and unverified."

    local api_url="https://cursor.com/api/download?platform=linux-x64&releaseTrack=latest&appName=cursor-nightly"
    local download_url=$(curl -s -L -H "User-Agent: $CURL_UA" "$api_url" | jq -r '.downloadUrl')

    if [[ -z "$download_url" || "$download_url" == "null" ]]; then
        status "Error: Could not get Nightly download URL."
        exit 1
    fi

    status "Downloading Cursor Nightly..."
    if ! curl -fsSL -H "User-Agent: $CURL_UA" "$download_url" -o "$temp_file"; then
        status "Error: Failed to download Cursor Nightly."
        exit 1
    fi
    chmod +x "$temp_file"

    local install_dir="$HOME/.local/share/cursor-nightly"

    cd /tmp
    rm -rf /tmp/squashfs-root
    "$temp_file" --appimage-extract >/dev/null 2>&1

    rm -rf "$install_dir"
    mv /tmp/squashfs-root "$install_dir"

    local binary=""
    for candidate in cursor-nightly cursor AppRun; do
        if [[ -x "$install_dir/$candidate" ]]; then
            binary="$install_dir/$candidate"
            break
        fi
    done

    if [[ -z "$binary" ]]; then
        status "Error: Could not find Cursor Nightly executable in extracted AppImage."
        exit 1
    fi

    mkdir -p "$HOME/.local/bin"
    rm -f "$HOME/.local/bin/cursor-nightly"
    ln -sf "$binary" "$HOME/.local/bin/cursor-nightly"

    mkdir -p "$HOME/.local/share/applications"
    cat > "$HOME/.local/share/applications/cursor-nightly.desktop" << EOL
[Desktop Entry]
Name=Cursor Nightly
Comment=AI-first code editor (Nightly)
Exec=$HOME/.local/bin/cursor-nightly
Icon=$install_dir/resources/app/resources/linux/code.png
Type=Application
StartupNotify=true
Categories=Development;
EOL
    chmod +x "$HOME/.local/share/applications/cursor-nightly.desktop"

    status "Cursor Nightly installed successfully."
)

install() {
    local track=$(get_cursor_release_track)
    status "Installing Cursor (Track: $track)..."

    case "$track" in
        stable)
            install_stable_signed
            ;;
        nightly)
            install_nightly_appimage
            ;;
        stable+nightly)
            install_stable_signed
            install_nightly_appimage
            ;;
        *)
            status "Unknown track: $track. Defaulting to stable."
            install_stable_signed
            ;;
    esac
}

uninstall_stable() {
    rm -rf "$HOME/.local/share/cursor"
    rm -f "$HOME/.local/bin/cursor"
    rm -f "$HOME/.local/share/applications/cursor.desktop"
}

uninstall_nightly() {
    rm -rf "$HOME/.local/share/cursor-nightly"
    rm -f "$HOME/.local/bin/cursor-nightly"
    rm -f "$HOME/.local/share/applications/cursor-nightly.desktop"
}

uninstall() {
    status "Uninstalling Cursor..."
    uninstall_stable
    uninstall_nightly
    rm -f "$CONFIG_FILE"
    rm -f "$HOME/.cache/manjikaze/keys/cursor_anysphere.asc"
    status "Uninstall complete."
}
