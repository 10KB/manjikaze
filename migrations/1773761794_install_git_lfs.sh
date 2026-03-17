#!/bin/bash
set -e

if command -v git-lfs &> /dev/null; then
    status "git-lfs is already installed, skipping."
    return 0
fi

status "Installing git-lfs..."
install_package "git-lfs" repo

if command -v git-lfs &> /dev/null; then
    git lfs install
    status "Git LFS installed and hooks configured."
fi
