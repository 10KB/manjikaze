#!/bin/bash
set -e

# The vlc package plays almost nothing on its own: the codecs, ffmpeg among them, come in plugin packages.

if ! is_installed "vlc"; then
    status "VLC is not installed, skipping."
    return 0
fi

install_package "vlc-plugins-all" repo
