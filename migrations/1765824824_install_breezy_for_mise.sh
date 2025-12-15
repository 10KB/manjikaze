#!/bin/bash
set -e

if ! command -v mise &> /dev/null; then
    status "mise is not installed, skipping breezy installation."
    return 0
fi

status "Installing breezy into mise Python environment..."
status "This allows brz to work correctly for building AUR packages that use Launchpad sources."

if mise exec python -- pip install breezy; then
    status "breezy installed successfully."
else
    status "Warning: Failed to install breezy. Some AUR packages may fail to build."
    status "You can try manually: mise exec python -- pip install breezy"
fi

