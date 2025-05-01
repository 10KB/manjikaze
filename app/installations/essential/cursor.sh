status "Installing Cursor from AppImage..."

# Create directories
mkdir -p ~/.local/share/applications
mkdir -p ~/.local/bin
mkdir -p ~/.local/share/cursor

# Get the latest version of cursor
CURSOR_DOWNLOAD_URL=$(curl -s "https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=latest" | jq -r '.downloadUrl')

if [[ -z "$CURSOR_DOWNLOAD_URL" ]]; then
    status "Failed to get Cursor download URL. Using fallback URL."
    CURSOR_DOWNLOAD_URL="https://download.cursor.sh/linux/appImage/x64/latest"
fi

# Download the AppImage
status "Downloading Cursor AppImage..."
curl -s -L "$CURSOR_DOWNLOAD_URL" -o /tmp/cursor.AppImage
chmod +x /tmp/cursor.AppImage

# Extract the AppImage
status "Extracting AppImage..."
cd /tmp
./cursor.AppImage --appimage-extract
rm /tmp/cursor.AppImage

# Move extracted content to installation directory
status "Installing Cursor..."
rm -rf ~/.local/share/cursor/* || true
mv /tmp/squashfs-root/* ~/.local/share/cursor/

# Create executable symlink
rm -f ~/.local/bin/cursor || true
ln -sf ~/.local/share/cursor/usr/bin/cursor ~/.local/bin/cursor

# Create desktop entry
cat > ~/.local/share/applications/cursor.desktop << EOL
[Desktop Entry]
Name=Cursor
Comment=AI-first code editor
GenericName=Text Editor
Exec=~/.local/bin/cursor %F
Icon=~/.local/share/cursor/code.png
Type=Application
StartupNotify=true
StartupWMClass=Cursor
Categories=TextEditor;Development;IDE;
MimeType=application/x-cursor-workspace;
Actions=new-empty-window;
Keywords=cursor;

[Desktop Action new-empty-window]
Name=New Empty Window
Exec=~/.local/bin/cursor --new-window %F
Icon=~/.local/share/cursor/code.png
EOL

# Set up VSCode configuration directory if it doesn't exist
if [ ! -d ~/.config/Code\ -\ OSS/User ]; then
    mkdir -p ~/.config/Code\ -\ OSS/User
    cp "$MANJIKAZE_DIR/configs/code.json" ~/.config/Code\ -\ OSS/User/settings.json
fi

status "Cursor installation complete!"
