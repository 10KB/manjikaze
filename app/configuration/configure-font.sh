setup_font=$(gum confirm "Do you want to install Cascadia Mono fonts?" --affirmative "Yes" --negative "No" --default=false && echo "true" || echo "false")

if [[ $setup_font == "true" ]]; then
    status "Installing Cascadia Mono fonts..."

    FONT_DIR="$HOME/.local/share/fonts"
    FONT_NAME="CascadiaMono"
    FONT_ZIP="${FONT_NAME}.zip"
    FONT_FOLDER="${FONT_NAME}Font"
    ORIGINAL_DIR=$(pwd)
    TMP_DIR=$(mktemp -d)

    cleanup() {
        cd "$ORIGINAL_DIR" || true
        [ -d "$TMP_DIR" ] && rm -rf "$TMP_DIR"
    }

    mkdir -p "$FONT_DIR"

    if fc-list | grep -q "$FONT_NAME"; then
        status "Cascadia Mono fonts are already installed."
        return 0
    fi

    cd "$TMP_DIR" || return 1

    if ! wget "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_ZIP}"; then
        status "Failed to download font archive."
        cleanup
        return 1
    fi

    if ! unzip "$FONT_ZIP" -d "$FONT_FOLDER"; then
        status "Failed to extract font archive."
        cleanup
        return 1
    fi

    if ! cp "$FONT_FOLDER"/*.ttf "$FONT_DIR"; then
        status "Failed to copy fonts to user directory."
        cleanup
        return 1
    fi

    fc-cache -f

    status "Cascadia Mono fonts have been installed."

    cleanup
fi
