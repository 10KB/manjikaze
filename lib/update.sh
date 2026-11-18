#!/bin/bash
# Steps of the system update that ask nothing: the checks before it starts and the package
# transactions. app/installations/update-installed-apps.sh puts them in order.

UPDATE_MIN_FREE_GIB=5

# Prints the free bytes on /, or nothing when df can't tell.
free_space_bytes() {
    df --output=avail --block-size=1 / 2>/dev/null | tail -n 1 | tr -d ' '
}

# A disk that fills up halfway through an update leaves a kernel without its initramfs, or an AUR
# package half built. pacman checks the space for its own transaction, but not for what follows.
update_has_free_space() {
    local free
    free=$(free_space_bytes)
    [[ ! $free =~ ^[0-9]+$ ]] || ((free >= UPDATE_MIN_FREE_GIB * 1024 * 1024 * 1024))
}

# checkupdates and paccache come with pacman-contrib.
ensure_update_tools() {
    if command -v checkupdates > /dev/null && command -v paccache > /dev/null; then
        return 0
    fi

    status "Installing pacman-contrib for checkupdates and paccache..."
    sudo pacman -S --needed --noconfirm --noprogressbar --quiet pacman-contrib
}

# Prints the repository packages that have an update, as "name old -> new". checkupdates syncs a
# copy of the package databases: syncing the system's own databases without upgrading would leave
# them newer than the installed packages, and a later install would be a partial upgrade.
list_repo_updates() {
    local updates exit_code=0
    updates=$(checkupdates 2> /dev/null) || exit_code=$?

    # checkupdates exits with 2 when there are no updates.
    case $exit_code in
        0) printf '%s\n' "$updates" | grep -v '\[ignored\]' || true ;;
        2) return 0 ;;
        *) return 1 ;;
    esac
}

# Keeps the two newest versions of every package, so a package can be downgraded without a
# download. Before the upgrade, the space it frees is there for the new packages.
prune_package_cache() {
    status "Removing older package versions from the package cache..."
    sudo paccache -rk2 || status "Could not prune the package cache."
}

# An upgrade of systemd re-executes the system manager and every user manager halfway through the
# transaction, which can kill a pacman that runs in the desktop session's cgroup. A scope of the
# system manager keeps pacman out of the session.
run_pacman_transaction() {
    if [[ -d /run/systemd/system ]]; then
        sudo systemd-run --scope --quiet --collect pacman "$@"
    else
        sudo pacman "$@"
    fi
}

# AUR builds use the system's tools instead of a mise shim, so /usr/bin goes first in their PATH.
# yay itself is looked up in the PATH as it is.
yay_system() {
    local yay
    yay=$(command -v yay) || return 1
    PATH="/usr/bin:$PATH" "$yay" "$@"
}
