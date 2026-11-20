#!/bin/bash

status() {
    gum log --time TimeOnly --structured --level info "$1"
}

get_version() {
    if [[ -f "$MANJIKAZE_DIR/VERSION" ]]; then
        cat "$MANJIKAZE_DIR/VERSION"
    else
        git -C "$MANJIKAZE_DIR" describe --tags 2>/dev/null || echo "dev"
    fi
}

# A system package ships a VERSION file instead of a git checkout. Its code
# directory is read-only, so per-user data lives in MANJIKAZE_DATA_DIR.
is_package_install() {
    [[ -f "$MANJIKAZE_DIR/VERSION" && ! -e "$MANJIKAZE_DIR/.git" ]]
}

is_installed() {
    pacman -Qi "$1" &> /dev/null
}

# Manjikaze's shell functions and defaults, in a file oh-my-zsh loads after its plugins. It's
# replaced whenever it differs, so a change reaches every workstation without editing ~/.zshrc.
refresh_shell_defaults() {
    local custom="$HOME/.oh-my-zsh/custom"
    if [[ ! -d $custom ]] || cmp -s "$MANJIKAZE_DIR/configs/zsh/manjikaze.zsh" "$custom/manjikaze.zsh"; then
        return 0
    fi
    cp "$MANJIKAZE_DIR/configs/zsh/manjikaze.zsh" "$custom/manjikaze.zsh" ||
        status "Could not update $custom/manjikaze.zsh."
}

# Opens a terminal that runs the command, for the button of a notification. The terminal stays open
# until Enter, so the output can be read.
open_in_terminal() {
    local wrapper=(bash -c '"$@"; code=$?; echo; read -rp "Press Enter to close this window. " _; exit "$code"' manjikaze-terminal)

    if command -v alacritty > /dev/null 2>&1; then
        alacritty -e "${wrapper[@]}" "$@"
    elif command -v kgx > /dev/null 2>&1; then
        kgx -- "${wrapper[@]}" "$@"
    elif command -v gnome-terminal > /dev/null 2>&1; then
        gnome-terminal -- "${wrapper[@]}" "$@"
    else
        status "No terminal found to run '$*' in."
        return 1
    fi
}

REBOOT_REQUIRED_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/manjikaze/reboot-required"

# A migration whose change only a reboot applies calls this with the reason, and the update offers
# a reboot. The request holds until the system boots again: the file starts with the boot id.
require_reboot() {
    local boot_id
    boot_id=$(cat /proc/sys/kernel/random/boot_id)
    mkdir -p "$(dirname "$REBOOT_REQUIRED_FILE")"
    if [[ ! -f $REBOOT_REQUIRED_FILE || $(head -n 1 "$REBOOT_REQUIRED_FILE") != "$boot_id" ]]; then
        echo "$boot_id" > "$REBOOT_REQUIRED_FILE"
    fi
    echo "$1" >> "$REBOOT_REQUIRED_FILE"
}

# Prints the reasons require_reboot recorded since the system booted.
required_reboot_reasons() {
    if [[ -f $REBOOT_REQUIRED_FILE && $(head -n 1 "$REBOOT_REQUIRED_FILE") == "$(cat /proc/sys/kernel/random/boot_id)" ]]; then
        tail -n +2 "$REBOOT_REQUIRED_FILE" | sort -u
    fi
}

disable_sleep() {
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
        status "Disabling screen lock and sleep during installation..."
        gsettings set org.gnome.desktop.screensaver lock-enabled false
        gsettings set org.gnome.desktop.session idle-delay 0
    fi
}

enable_sleep() {
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
        status "Re-enabling screen lock and sleep..."
        gsettings set org.gnome.desktop.screensaver lock-enabled true
        gsettings set org.gnome.desktop.session idle-delay 300
    fi
}

start_sudo_keepalive() {
    if [[ -n "${_SUDO_KEEPALIVE_PID:-}" ]] && kill -0 "$_SUDO_KEEPALIVE_PID" 2>/dev/null; then
        return 0 # Already running
    fi
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    _SUDO_KEEPALIVE_PID=$!
}

stop_sudo_keepalive() {
    if [[ -n "${_SUDO_KEEPALIVE_PID:-}" ]]; then
        kill "$_SUDO_KEEPALIVE_PID" 2>/dev/null || true
        wait "$_SUDO_KEEPALIVE_PID" 2>/dev/null || true
        unset _SUDO_KEEPALIVE_PID
    fi
}

activate_zsh_plugin() {
    local plugin="$1"
    local zshrc="$HOME/.zshrc"
    local plugins_line=$(grep -E "^plugins=\([^)]*\)" "$zshrc")

    if [ -z "$plugins_line" ]; then
        status "No plugins line found in .zshrc. Skipping oh-my-zsh plugin activation."
        return 1
    fi

    if [[ "$plugins_line" == *"$plugin"* ]]; then
        status "Plugin '$plugin' is already activated."
        return 0
    fi

    local plugins_content=$(echo "$plugins_line" | sed -E 's/^plugins=\((.*)\)/\1/')
    local new_plugins_content

    if [ -z "$plugins_content" ]; then
        new_plugins_content="$plugin"
    else
        new_plugins_content="$plugins_content $plugin"
    fi

    sed -i "s/^plugins=([^)]*)$/plugins=($new_plugins_content)/" "$zshrc"

    status "Activated oh-my-zsh plugin: $plugin"
    return 0
}

deactivate_zsh_plugin() {
    local plugin="$1"
    local zshrc="$HOME/.zshrc"
    local plugins_line=$(grep -E "^plugins=\([^)]*\)" "$zshrc")

    if [ -z "$plugins_line" ]; then
        status "No plugins line found in .zshrc. Skipping oh-my-zsh plugin deactivation."
        return 1
    fi

    if [[ "$plugins_line" != *"$plugin"* ]]; then
        status "Plugin '$plugin' is not activated."
        return 0
    fi

    # Handle various cases where plugin might be in the middle, start, or end of the list
    sed -i -E "s/plugins=\(([^)]*)$plugin([^)]*)\)/plugins=(\1\2)/" "$zshrc"

    # Clean up any duplicate spaces
    sed -i -E "s/plugins=\(([^)]*) {2,}([^)]*)\)/plugins=(\1 \2)/" "$zshrc"

    # Clean up leading/trailing spaces in plugin list
    sed -i -E "s/plugins=\( (.*)\)/plugins=(\1)/" "$zshrc"
    sed -i -E "s/plugins=\((.*) \)/plugins=(\1)/" "$zshrc"

    status "Deactivated oh-my-zsh plugin: $plugin"
    return 0
}

GNOME_CUSTOM_KEYBINDINGS_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"

add_gnome_shortcut() {
    local id=$1
    local name=$2
    local command=$3
    local binding=$4

    if [[ "$XDG_CURRENT_DESKTOP" != *"GNOME"* ]]; then
        return 0
    fi

    local path="$GNOME_CUSTOM_KEYBINDINGS_PATH/$id/"
    local schema="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path"
    local current
    current=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)

    if [[ "$current" != *"'$path'"* ]]; then
        if [[ "$current" == "@as []" || "$current" == "[]" ]]; then
            current="['$path']"
        else
            current="${current%]}, '$path']"
        fi
        gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$current"
    fi

    gsettings set "$schema" name "$name"
    gsettings set "$schema" command "$command"
    gsettings set "$schema" binding "$binding"
    status "Configured shortcut $binding for $name."
}

remove_gnome_shortcut() {
    local id=$1

    if [[ "$XDG_CURRENT_DESKTOP" != *"GNOME"* ]]; then
        return 0
    fi

    local path="$GNOME_CUSTOM_KEYBINDINGS_PATH/$id/"
    local current
    current=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)

    if [[ "$current" != *"'$path'"* ]]; then
        return 0
    fi

    current=$(echo "$current" | sed -e "s|'$path'||" -e 's/\[, /[/' -e 's/, ,/,/' -e 's/, \]/]/')
    if [[ "$current" == "[]" ]]; then
        current="@as []"
    fi

    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$current"
    gsettings reset-recursively "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path"
    status "Removed shortcut for $id."
}

install_package() {
    local package=$1
    local type=${2:-repo} # Default to repo

    if is_installed "$package"; then
        status "Package '$package' is already installed. Skipping."
        return 0
    fi

    set +e
    local output
    if [[ "$type" == "aur" ]]; then
        status "Installing AUR package $package..."
        # Ensure system tools use system Python for building AUR packages
        output=$(PATH=/usr/bin:$PATH yay -S "$package" --noconfirm --noprogressbar --quiet 2>&1)
    else
        status "Installing repository package $package..."
        output=$(sudo pacman -S "$package" --noconfirm --noprogressbar --quiet 2>&1)
    fi
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        status "Failed to install $package"
        printf '%s\n' "$output" | tail -n 5

        if ! gum confirm "Continue with installation of other packages?"; then
            return 2 # Special code to indicate user-requested abort
        fi

        status "Continuing installation process..."
        return 1 # Indicate failure but script continues
    else
        status "Package '$package' installed successfully."
    fi
    set -e
}

rebuild_package() {
    local package=$1
    local type=${2:-repo} # Default to repo

    set +e
    local output
    if [[ "$type" == "aur" ]]; then
        status "Rebuilding AUR package $package..."
        # Ensure system tools use system Python for building AUR packages
        output=$(PATH=/usr/bin:$PATH yay -S "$package" --noconfirm --noprogressbar--rebuild 2>&1)
    else
        status "Reinstalling repository package $package..."
        output=$(sudo pacman -S "$package" --noprogressbar --noconfirm 2>&1)
    fi
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        status "Failed to rebuild $package"
        return 1
    else
        status "Package '$package' rebuilt successfully."
    fi
    set -e
}

uninstall_package() {
    local package=$1
    local type=${2:-repo} # Default to repo

    if ! is_installed "$package"; then
        status "Package '$package' is not installed. Skipping."
        return 0
    fi

    set +e
    local output
    if [[ "$type" == "aur" ]]; then
        status "Uninstalling AUR package $package and its unused dependencies..."
        output=$(yay -Rs "$package" --noconfirm --noprogressbar 2>&1)
    else
        status "Uninstalling repository package $package and its unused dependencies..."
        # pacman -R has no --quiet option and stops when it is given.
        output=$(sudo pacman -Rs "$package" --noconfirm --noprogressbar 2>&1)
    fi
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        status "Failed to uninstall $package"
        printf '%s\n' "$output" | tail -n 5

        if ! gum confirm "Continue with uninstallation of other packages?"; then
            return 2 # Special code to indicate user-requested abort
        fi

        status "Continuing uninstallation process..."
        return 1 # Indicate failure but script continues
    else
        status "Package '$package' uninstalled successfully."
    fi
    set -e
}

# Copies a file to a system path. sudo only runs when the file there differs.
install_system_file() {
    local source=$1 target=$2
    if cmp -s "$source" "$target"; then
        return 0
    fi
    sudo mkdir -p "$(dirname "$target")"
    sudo cp "$source" "$target"
}

# A CLI that Arch packages lag behind on comes from mise, at the version in
# configs/mise/<tool>.toml, named after the mise tool: a pinned version, or "latest" for a CLI
# that releases too often to pin. Manjikaze owns the copy in ~/.config/mise/conf.d, so a change
# in Manjikaze reaches every workstation with the next update.
MISE_MANAGED_DIR="$HOME/.config/mise/conf.d"

# "latest" means the newest release that is at least this old, so a broken or compromised
# release has time to come to light. Pinned versions don't depend on it.
MISE_MANAGED_MIN_RELEASE_AGE="24h"

# From $HOME, so the mise.toml of a project doesn't apply.
managed_mise() {
    (cd "$HOME" && MISE_MINIMUM_RELEASE_AGE=$MISE_MANAGED_MIN_RELEASE_AGE mise "$@")
}

# The version in the line <tool> = "<version>" or <tool> = { version = "<version>", ... } of
# configs/mise/<tool>.toml.
managed_mise_version() {
    sed -n -E "s/^$1 = (\{ *version = )?\"([^\"]*)\".*$/\2/p" "$MANJIKAZE_DIR/configs/mise/$1.toml"
}

# The tools installed with install_mise_tool that this Manjikaze still has a version file for.
managed_mise_tools() {
    local file tool
    for file in "$MISE_MANAGED_DIR"/manjikaze-*.toml; do
        tool=$(basename "$file" .toml)
        tool=${tool#manjikaze-}
        if [[ -f $file && -f "$MANJIKAZE_DIR/configs/mise/$tool.toml" ]]; then
            echo "$tool"
        fi
    done
}

# install_mise_tool <tool> [<copy> <program>...]: the copy that the vendor's own installer made,
# and the programs it linked into ~/.local/bin, make way once mise has installed the tool.
install_mise_tool() {
    local tool=$1 vendor_copy=${2:-} version
    local vendor_programs=("${@:3}")

    if ! command -v mise &> /dev/null; then
        status "mise is not installed. Install the essential apps first."
        return 1
    fi

    mkdir -p "$MISE_MANAGED_DIR"
    cp "$MANJIKAZE_DIR/configs/mise/$tool.toml" "$MISE_MANAGED_DIR/manjikaze-$tool.toml"

    version=$(managed_mise_version "$tool")
    status "Installing $tool $version with mise..."
    if ! managed_mise install "$tool@$version"; then
        status "Failed to install $tool with mise."
        return 1
    fi
    if [[ -n $vendor_copy ]]; then
        remove_vendor_install "$vendor_copy" "${vendor_programs[@]}"
    fi
    link_mise_tool "$tool"
    status "Installed $tool with mise."
}

# remove_vendor_install <copy> <program>...: removes the links ~/.local/bin/<program> into the
# copy, and the copy itself, a directory or a file. The copy stays while a process runs from it:
# such a process may start itself again.
remove_vendor_install() {
    local copy=$1 name=$2 program link proc exe
    for program in "${@:2}"; do
        link="$HOME/.local/bin/$program"
        if [[ -L $link && $(readlink "$link") == "$copy"/* ]]; then
            rm "$link"
        fi
    done
    if [[ -L $copy || ! -e $copy ]]; then
        return 0
    fi

    for proc in /proc/[0-9]*/exe; do
        exe=$(readlink "$proc" 2> /dev/null) || continue
        if [[ $exe == "$copy" || $exe == "$copy"/* ]]; then
            status "$name still runs from $copy. Close it and choose it again to remove that copy."
            return 0
        fi
    done
    rm -rf "$copy"
    status "Removed the $name that its own installer put in $copy."
}

uninstall_mise_tool() {
    local tool=$1
    unlink_mise_tool "$tool"
    rm -f "$MISE_MANAGED_DIR/manjikaze-$tool.toml"
    status "Removed $tool from the mise configuration. Run 'mise prune' to delete versions nothing uses."
}

# Outside a shell where mise is active, such as in a desktop app, the tool runs through links in
# ~/.local/bin to the programs of Manjikaze's version. Never through mise's shims: a shim takes
# its version from the mise.toml or .tool-versions of the directory it runs in, so a project
# would decide what runs on the host. For "latest", the links go through mise's latest
# directory, which moves along with every upgrade.
link_mise_tool() {
    local tool=$1 version bin_dir program link
    version=$(managed_mise_version "$tool")
    mkdir -p "$HOME/.local/bin"

    while read -r bin_dir; do
        for program in "$bin_dir"/*; do
            if [[ ! -f $program || ! -x $program ]]; then
                continue
            fi
            link="$HOME/.local/bin/$(basename "$program")"
            if [[ -e $link || -L $link ]] && [[ $(readlink "$link") != */mise/installs/"$tool"/* ]]; then
                status "Not linking $link: it exists and isn't a link to $tool."
                continue
            fi
            ln -sfn "$program" "$link"
        done
    done < <(cd "$HOME" && mise bin-paths "$tool@$version")
}

unlink_mise_tool() {
    local tool=$1 link
    for link in "$HOME/.local/bin"/*; do
        if [[ -L $link && $(readlink "$link") == */mise/installs/"$tool"/* ]]; then
            rm "$link"
        fi
    done
}

link_mise_tools() {
    local tool
    while read -r tool; do
        link_mise_tool "$tool"
    done < <(managed_mise_tools)
}

# Copies the versions this Manjikaze sets over the managed files of the tools that are installed.
refresh_mise_tools() {
    local tool
    while read -r tool; do
        cp "$MANJIKAZE_DIR/configs/mise/$tool.toml" "$MISE_MANAGED_DIR/manjikaze-$tool.toml"
    done < <(managed_mise_tools)
}

# Prints "<tool> <installed version> <newer version>" for the tools on "latest" that have a
# release that is old enough.
outdated_mise_tools() {
    local tools
    readarray -t tools < <(managed_mise_tools)
    if [[ ${#tools[@]} -eq 0 ]]; then
        return 0
    fi
    managed_mise outdated --json "${tools[@]}" 2> /dev/null |
        jq -r '.[] | select(.current != null) | "\(.name) \(.current) \(.latest)"' || true
}

# Installs the managed tools that are missing and upgrades the ones on "latest".
upgrade_mise_tools() {
    local tools
    readarray -t tools < <(managed_mise_tools)
    if [[ ${#tools[@]} -eq 0 ]]; then
        return 0
    fi
    managed_mise install "${tools[@]}" && managed_mise upgrade "${tools[@]}"
}

