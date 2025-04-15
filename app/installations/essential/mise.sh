install_package "mise" aur
activate_zsh_plugin "mise"

if [ ! -d ~/.config/mise ]; then
    mkdir -p ~/.config/mise
    cp "$MANJIKAZE_DIR/configs/mise.toml" ~/.config/mise/config.toml
    status "Configured mise with default settings"
fi

status "Installing default runtimes (Node.js LTS and Python)..."
mise install node python

status "Installing essential global packages..."
mise exec -- npm install -g yarn
mise exec -- pip install pipx
