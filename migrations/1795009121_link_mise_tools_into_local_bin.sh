#!/bin/bash
set -e

# Outside a shell where mise is active, such as in a desktop app, tools that Manjikaze installs
# with mise weren't found. They now get links in ~/.local/bin to the pinned version's programs.

if ! command -v mise &> /dev/null; then
    return 0
fi

link_mise_tools
