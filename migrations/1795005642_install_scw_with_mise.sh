#!/bin/bash
set -e

# Arch's scaleway-cli lags months behind upstream, so scw moves to mise at the version that
# configs/mise/scaleway.toml pins. The Arch package goes only once mise has installed scw.

if ! pacman -Qq scaleway-cli &> /dev/null; then
    return 0
fi

if ! command -v mise &> /dev/null; then
    status "scw stays on the Arch package: install the essential apps for mise, then reinstall scw."
    return 0
fi

if ! install_mise_tool scaleway; then
    return 1
fi
uninstall_package scaleway-cli repo
