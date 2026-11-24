#!/bin/bash
set -e

# Manjaro's stable branch gets a Tailscale release weeks after it comes out, and with the tailscale
# package installed Tailscale's own updater refuses to run. Tailscale moves to the binaries that
# Tailscale publishes, which keep themselves up to date.

if ! command -v tailscaled &> /dev/null; then
    return 0
fi

# Switching on the updates takes a running tailscaled.
if ! systemctl is-active --quiet tailscaled.service; then
    status "Tailscale isn't running, so it stays as it is. Install the optional tailscale app to move it to Tailscale's own binaries."
    return 0
fi

# pacman keeps a package that another one depends on, and a failed migration would hold up the rest.
if is_installed tailscale && ! pacman -Qttq tailscale &> /dev/null; then
    status "Another package depends on the tailscale package, so Tailscale stays as it is."
    return 0
fi

source "$MANJIKAZE_DIR/lib/tailscale.sh"
install_tailscale_binaries
enable_tailscale_updates
