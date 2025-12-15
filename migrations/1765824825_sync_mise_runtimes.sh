#!/bin/bash
set -e

if ! command -v mise &> /dev/null; then
    status "mise is not installed, skipping runtime sync."
    return 0
fi

status "Syncing mise runtimes to ensure all configured versions are installed..."

if mise install; then
    status "mise runtimes synced successfully."
else
    status "Warning: Failed to sync mise runtimes. Run 'mise install' manually to fix."
fi

