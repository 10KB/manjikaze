install_package 'rbenv' aur
install_package 'ruby-build' aur
install_package 'ruby-erb' repo

# Create oh-my-zsh custom plugins directory for rbenv
mkdir -p "$HOME/.oh-my-zsh/custom/plugins/rbenv"

# Create rbenv plugin file
cat > "$HOME/.oh-my-zsh/custom/plugins/rbenv/rbenv.plugin.zsh" << 'EOF'
eval "$(rbenv init -)"
EOF

# Add rbenv to plugins list in .zshrc if it's not already there
if [ -f "$HOME/.zshrc" ]; then
    if ! grep -q "plugins=.*rbenv" "$HOME/.zshrc"; then
        sed -i 's/^plugins=(\(.*\))/plugins=(\1 rbenv)/' "$HOME/.zshrc"
    fi
fi
