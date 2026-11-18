#!/bin/bash
# Steps of the system update that ask nothing: the checks before it starts and the package
# transactions. app/installations/update-installed-apps.sh puts them in order.

UPDATE_MIN_FREE_GIB=5

# manjikaze update -y sets UPDATE_UNATTENDED: it asks nothing and updates everything it finds.
update_unattended() {
    [[ ${UPDATE_UNATTENDED:-false} == true ]]
}

# Asks a question about what to update, which an unattended update answers with yes.
update_confirm() {
    update_unattended || gum confirm "$@"
}

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

# Where the checks below look. Tests point them at a scratch directory.
UPDATE_KERNEL_MODULES_DIR="${UPDATE_KERNEL_MODULES_DIR:-/usr/lib/modules}"
UPDATE_BOOT_DIR="${UPDATE_BOOT_DIR:-/boot}"
UPDATE_SYS_MODULE_DIR="${UPDATE_SYS_MODULE_DIR:-/sys/module}"

# A kernel package removes the modules of the version it replaces, so the running kernel can't load
# a module it hasn't loaded yet, such as the driver for a device plugged in later. Only modules that
# a package owns count: kernel-modules-hook keeps a copy of the running kernel's modules.
running_kernel_installed() {
    local builtin
    builtin="$UPDATE_KERNEL_MODULES_DIR/$(uname -r)/modules.builtin"
    [[ -f $builtin ]] && pacman -Qo "$builtin" > /dev/null 2>&1
}

# Microcode loads at boot, so an update of it only takes effect after a reboot.
microcode_updated_since_boot() {
    local boot_time image
    boot_time=$(awk '/^btime/ {print $2}' /proc/stat)
    for image in "$UPDATE_BOOT_DIR"/*-ucode.img; do
        if [[ -f $image ]] && (($(stat -c %Y "$image") > boot_time)); then
            return 0
        fi
    done
    return 1
}

# The NVIDIA kernel module and its libraries have to be the same version. After an update of the
# driver, the loaded module stays the old one until a reboot, and apps that use the GPU fail.
nvidia_driver_updated() {
    local loaded installed
    loaded=$(cat "$UPDATE_SYS_MODULE_DIR/nvidia/version" 2> /dev/null) || return 1
    installed=$(modinfo -F version nvidia 2> /dev/null) || return 1
    [[ -n $loaded && -n $installed && $loaded != "$installed" ]]
}

# Prints why the system needs a reboot, one reason per line, or nothing.
reboot_reasons() {
    if ! running_kernel_installed; then
        echo "The running kernel $(uname -r) was replaced, so drivers that aren't loaded yet can't load."
    fi
    if microcode_updated_since_boot; then
        echo "The CPU microcode was updated, and it loads at boot."
    fi
    if nvidia_driver_updated; then
        echo "The NVIDIA driver was updated, so apps that use the GPU fail until the new one loads."
    fi
    required_reboot_reasons
}

UPDATE_LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/manjikaze/updates"
UPDATE_LOGS_KEPT=60

# Prints the path for the log of a new update, and removes the oldest logs so that
# UPDATE_LOGS_KEPT remain with the new one.
new_update_log() {
    mkdir -p "$UPDATE_LOG_DIR" || return 1

    local old
    printf '%s\n' "$UPDATE_LOG_DIR"/update-*.log | sort -r | tail -n +"$UPDATE_LOGS_KEPT" |
        while read -r old; do
            if [[ -f $old ]]; then
                rm -f -- "$old"
            fi
        done

    echo "$UPDATE_LOG_DIR/update-$(date +%Y-%m-%dT%H%M%S).log"
}

# The log records a terminal: colours and carriage returns come off before it's searched.
plain_update_log() {
    sed -e 's/\x1b\[[0-9;?]*[A-Za-z]//g' -e 's/\r$//' "$1"
}

# Reports what an update's log shows beyond the exit codes: initramfs images that weren't built or
# may be incomplete, DKMS modules that didn't build, and new .pacnew and .pacsave files. Fails when
# an initramfs image wasn't built, because the system may not boot then.
check_update_log() {
    local text builds finished
    [[ -f $1 ]] || return 0
    text=$(plain_update_log "$1")

    # mkinitcpio ends every image it builds with "successful", or with the warning that errors were
    # encountered. A build with neither ended before it wrote its image.
    builds=$(grep -c "Building image from preset" <<< "$text" || true)
    finished=$(grep -c -E "Initcpio image generation successful|errors were encountered during the build" <<< "$text" || true)
    if grep -q "image generation FAILED" <<< "$text" || ((finished < builds)); then
        status "An initramfs image wasn't built, so the system may not boot. Don't reboot before you fix it: look for mkinitcpio in $1."
        return 1
    fi

    if grep -q "errors were encountered during the build" <<< "$text"; then
        status "mkinitcpio reported errors while building an initramfs image, so the image may not be complete:"
        grep "==> ERROR:" <<< "$text" | sort -u | sed 's/^/  /'
    fi

    if grep -q "Error! " <<< "$text"; then
        status "A DKMS kernel module didn't build, so it won't load after a reboot:"
        grep "Error! " <<< "$text" | sort -u | sed 's/^/  /'
    fi

    local new_files
    new_files=$(grep -o -E "(installed|saved) as [^ ]+\.(pacnew|pacsave)" <<< "$text" | awk '{print $3}' | sort -u)
    if [[ -n $new_files ]]; then
        status "These configuration files have a new version next to them. Merge them, for example with 'sudo pacdiff':"
        sed 's/^/  /' <<< "$new_files"
    fi
}
