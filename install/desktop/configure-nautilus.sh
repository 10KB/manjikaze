status "Configuring Nautilus file manager..."

sudo pacman -S imagemagick nautilus-image-converter --noconfirm

# Configure Nautilus to open in list view and use smallest icon size
gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
gsettings set org.gnome.nautilus.list-view default-zoom-level 'small'

# Enable sorting folders before files in Nautilus
gsettings set org.gnome.nautilus.preferences default-sort-order 'name'

# Configure Nautilus to show hidden files
gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first true
gsettings set org.gtk.Settings.FileChooser sort-directories-first true

# Create Webdev directory in home folder
mkdir -p ~/Webdev

# Add bookmark for Webdev directory in Nautilus
echo "file://$HOME/Webdev" >> ~/.config/gtk-3.0/bookmarks

# Ensure the bookmark is unique (remove duplicates if any)
sort -u ~/.config/gtk-3.0/bookmarks -o ~/.config/gtk-3.0/bookmarks
