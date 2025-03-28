install_if_not_present "nosql-workbench" "yay -S nosql-workbench --noconfirm --noprogressbar --quiet"
chmod +x $HOME/.local/bin/nosql-workbench && cat > $HOME/.local/share/applications/nosql-workbench.desktop << EOL
[Desktop Entry]
Name=NoSQL Workbench
Comment=AWS DynamoDB NoSQL Workbench
Exec=gnome-terminal -- $HOME/.local/bin/nosql-workbench
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=Development;Database;
EOL" 