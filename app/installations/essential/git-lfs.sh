install() {
    install_package "git-lfs" repo

    if command -v git-lfs &> /dev/null; then
        git lfs install
        status "Git LFS hooks installed."
    fi
}

uninstall() {
    git lfs uninstall 2>/dev/null || true
    uninstall_package "git-lfs" repo
}
