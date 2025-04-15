install_package 'rbenv' aur
install_package 'ruby-build' aur
install_package 'ruby-erb' repo

# Add rbenv to PATH for both bash and zsh
for shell in bash zsh; do
    if [ -f "$HOME/.${shell}rc" ]; then
        if ! grep -q "rbenv init" "$HOME/.${shell}rc"; then
            echo 'eval "$(rbenv init -)"' >> "$HOME/.${shell}rc"
        fi
    fi
done
