#!/bin/bash

# Tailscale comes from the static binaries that Tailscale publishes, not from the tailscale
# package. Manjaro's stable branch gets a release weeks after it comes out, and with the package
# installed Tailscale's own updater refuses to run. tailscaled only starts that updater from
# /usr/bin or /usr/local/bin.
TAILSCALE_PKGS_URL="https://pkgs.tailscale.com/stable"
# The tests install into a root of their own.
TAILSCALE_ROOT="${TAILSCALE_ROOT:-}"
TAILSCALE_BIN_DIR="$TAILSCALE_ROOT/usr/local/bin"
TAILSCALE_UNIT_DIR="$TAILSCALE_ROOT/etc/systemd/system"
TAILSCALE_DEFAULTS="$TAILSCALE_ROOT/etc/default/tailscaled"
TAILSCALE_COMPLETION="$TAILSCALE_ROOT/usr/local/share/zsh/site-functions/_tailscale"

tailscale_running() {
    tailscale status --json 2> /dev/null | grep -q '"BackendState": "Running"'
}

# Downloads the latest release and unpacks it in the directory, ready to put in place. The checksum
# comes from the same server, so it only catches a broken download. Tailscale checks the updates
# after this one against its signing keys itself.
download_tailscale() {
    local release=$1 tarball checksum

    if ! tarball=$(curl -sf "$TAILSCALE_PKGS_URL/?mode=json" | jq -er '.Tarballs.amd64') ||
        [[ ! $tarball =~ ^tailscale_[0-9.]+_amd64\.tgz$ ]]; then
        status "Could not find the latest Tailscale release."
        return 1
    fi

    status "Downloading ${tarball%_amd64.tgz}..."
    if ! curl -sfL -o "$release/$tarball" "$TAILSCALE_PKGS_URL/$tarball" ||
        ! checksum=$(curl -sfL "$TAILSCALE_PKGS_URL/$tarball.sha256"); then
        status "Could not download Tailscale."
        return 1
    fi
    if ! echo "$checksum  $release/$tarball" | sha256sum --check --status; then
        status "The Tailscale download doesn't match its checksum."
        return 1
    fi

    if ! tar -xzf "$release/$tarball" -C "$release" --strip-components=1 ||
        [[ ! -f "$release/tailscale" || ! -f "$release/tailscaled" ]] ||
        [[ ! -f "$release/systemd/tailscaled.service" || ! -f "$release/systemd/tailscaled.defaults" ]]; then
        status "The Tailscale download doesn't hold what Manjikaze expects."
        return 1
    fi

    # The units start Tailscale from /usr/bin and /usr/sbin.
    mv "$release/systemd/tailscaled.defaults" "$release/"
    sed -i 's|/usr/s\?bin/tailscale|/usr/local/bin/tailscale|g' "$release"/systemd/*
}

# pacman keeps a changed /etc/default/tailscaled as .pacsave.
place_tailscale_defaults() {
    if [[ -f "$TAILSCALE_DEFAULTS.pacsave" ]]; then
        sudo mv "$TAILSCALE_DEFAULTS.pacsave" "$TAILSCALE_DEFAULTS"
    elif [[ ! -f $TAILSCALE_DEFAULTS ]]; then
        sudo install -D -m 644 "$1/tailscaled.defaults" "$TAILSCALE_DEFAULTS"
    fi
}

# Puts an unpacked release in place of the tailscale package. tailscaled stays enabled if it was,
# and is restarted if it runs. The package goes first, so nothing has changed when pacman refuses.
place_tailscale() {
    local release=$1 enabled=false output

    if systemctl is-enabled --quiet tailscaled.service 2> /dev/null; then
        enabled=true
    fi

    # pacman -R has no --quiet option and stops when it is given.
    if is_installed tailscale && ! output=$(sudo pacman -R tailscale --noconfirm --noprogressbar 2>&1); then
        status "Could not remove the tailscale package, so Tailscale stays as it is."
        printf '%s\n' "$output" | tail -n 5
        return 1
    fi

    if ! sudo install -D -m 755 -t "$TAILSCALE_BIN_DIR" "$release/tailscale" "$release/tailscaled" ||
        ! sudo install -D -m 644 -t "$TAILSCALE_UNIT_DIR" "$release"/systemd/* ||
        ! place_tailscale_defaults "$release"; then
        status "Could not put Tailscale in place. Check the errors above, then install the tailscale app again."
        return 1
    fi

    # The package brought the completion for zsh. The binary prints its own.
    if ! "$release/tailscale" completion zsh > "$release/_tailscale" ||
        ! sudo install -D -m 644 "$release/_tailscale" "$TAILSCALE_COMPLETION"; then
        status "Could not install the zsh completion for tailscale."
    fi
    # This shell may remember tailscale in /usr/bin.
    hash -r

    sudo systemctl daemon-reload
    if [[ $enabled == true ]]; then
        # The link that enables tailscaled still points at the unit of the package.
        sudo systemctl reenable tailscaled.service || status "Could not enable the Tailscale daemon."
    fi

    # Last: a session over Tailscale SSH ends when tailscaled restarts.
    if ! sudo systemctl try-restart tailscaled.service; then
        status "Tailscale is in $TAILSCALE_BIN_DIR, but tailscaled didn't restart. Check 'systemctl status tailscaled'."
        return 1
    fi
}

# Installs the latest Tailscale in /usr/local/bin, unless it is already there.
install_tailscale_binaries() {
    local release exit_code=0

    if [[ -x "$TAILSCALE_BIN_DIR/tailscaled" ]] && ! is_installed tailscale; then
        return 0
    fi

    release=$(mktemp -d)
    if download_tailscale "$release" && place_tailscale "$release"; then
        status "Installed Tailscale in $TAILSCALE_BIN_DIR."
    else
        exit_code=1
    fi
    rm -rf "$release"
    return "$exit_code"
}

# Tailscale then installs every new release itself. It takes a running tailscaled.
enable_tailscale_updates() {
    sudo tailscale set --auto-update ||
        status "Could not switch on Tailscale's automatic updates. Run 'sudo tailscale set --auto-update' once tailscaled runs."
}

install_tailscale() {
    install_tailscale_binaries || return 1

    if ! sudo systemctl enable --now tailscaled.service; then
        status "Failed to start the Tailscale daemon."
        return 1
    fi

    enable_tailscale_updates
}

log_in_to_tailscale() {
    if tailscale_running; then
        return 0
    fi

    status "Log in to Tailscale with the link below..."
    if ! sudo tailscale up; then
        status "Tailscale login failed. Run 'sudo tailscale up' to try again."
        return 1
    fi
}

uninstall_tailscale() {
    if ! command -v tailscaled &> /dev/null; then
        status "Tailscale is not installed. Skipping."
        return 0
    fi

    sudo systemctl disable --now tailscaled.service || status "Failed to stop the Tailscale daemon."

    if is_installed tailscale; then
        uninstall_package "tailscale" repo
    fi
    sudo rm -f "$TAILSCALE_BIN_DIR/tailscale" "$TAILSCALE_BIN_DIR/tailscaled" \
        "$TAILSCALE_UNIT_DIR/tailscaled.service" "$TAILSCALE_UNIT_DIR/tailscale-online.target" \
        "$TAILSCALE_UNIT_DIR/tailscale-wait-online.service" "$TAILSCALE_DEFAULTS" "$TAILSCALE_COMPLETION"
    sudo systemctl daemon-reload

    status "Tailscale removed. This machine stays in your tailnet, with its key in /var/lib/tailscale, until you remove it in the admin console."
}
