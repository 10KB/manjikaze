#!/bin/bash

# ── Helper: run gpg in non-interactive batch mode ──────────────────────
gpg_batch() {
    gpg --command-fd=0 --pinentry-mode=loopback "$@"
}

get_pinentry_program() {
    echo "$HOME/.gnupg/pinentry-proxy.py"
}

create_pinentry_proxy() {
    local proxy_path="$HOME/.gnupg/pinentry-proxy.py"
    local real_pinentry
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
        real_pinentry="/usr/bin/pinentry-gnome3"
    else
        real_pinentry="/usr/bin/pinentry-gtk"
    fi

    cat > "$proxy_path" << "EOF"
#!/usr/bin/env python3
import sys
import subprocess
import os

REAL_PINENTRY = "REAL_PINENTRY_PLACEHOLDER"
PIN_FILE = os.path.expanduser("~/.gnupg/.yubikey-pin")

def main():
    try:
        p = subprocess.Popen([REAL_PINENTRY], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True, bufsize=1)
    except Exception:
        sys.stdout.write("ERR 83886179 cannot execute real pinentry\n")
        sys.stdout.flush()
        return

    greeting = p.stdout.readline()
    sys.stdout.write(greeting)
    sys.stdout.flush()

    desc = ""
    for line in sys.stdin:
        if line.startswith("SETDESC"):
            desc = line[8:].strip()

        if line.startswith("GETPIN"):
            desc_lower = desc.lower()
            if "admin" not in desc_lower and "reset code" not in desc_lower and "puk" not in desc_lower:
                if os.path.exists(PIN_FILE):
                    try:
                        with open(PIN_FILE, "r") as f:
                            pin = f.read().strip()
                        sys.stdout.write(f"D {pin}\n")
                        sys.stdout.write("OK\n")
                        sys.stdout.flush()
                        continue
                    except Exception:
                        pass

        p.stdin.write(line)
        p.stdin.flush()

        while True:
            resp = p.stdout.readline()
            if not resp:
                break
            sys.stdout.write(resp)
            sys.stdout.flush()
            if resp.startswith("OK") or resp.startswith("ERR"):
                break

if __name__ == "__main__":
    main()
EOF
    sed -i "s|REAL_PINENTRY_PLACEHOLDER|$real_pinentry|" "$proxy_path"
    chmod +x "$proxy_path"
}

setup_gpg_config() {
    local pinentry_program
    pinentry_program=$(get_pinentry_program)

    status "Using pinentry: $(basename "$pinentry_program")"

    status "Stopping any running GPG agent services..."
    systemctl --user stop gpg-agent.socket gpg-agent.service gpg-agent-ssh.socket gpg-agent-extra.socket gpg-agent-browser.socket 2>/dev/null || true
    gpgconf --kill all 2>/dev/null || true

    sudo systemctl restart pcscd
    if [[ $? -ne 0 ]]; then
        status "Warning: Could not restart pcscd"
    fi
    sleep 2

    # Disable gnome-keyring SSH agent to prevent conflict with gpg-agent
    local gk_desktop="/etc/xdg/autostart/gnome-keyring-ssh.desktop"
    local gk_override="$HOME/.config/autostart/gnome-keyring-ssh.desktop"
    if [[ -f "$gk_desktop" ]] && [[ ! -f "$gk_override" ]]; then
        status "Disabling gnome-keyring SSH agent to avoid conflict with gpg-agent..."
        mkdir -p "$HOME/.config/autostart"
        cp "$gk_desktop" "$gk_override"
        echo "Hidden=true" >> "$gk_override"
    fi

    status "Removing existing GPG configuration..."
    rm -rf ~/.gnupg
    mkdir -p ~/.gnupg
    chmod 700 ~/.gnupg

    # Create the Python proxy script for automatic PIN entry
    create_pinentry_proxy

    status "Configuring GPG for YubiKey usage..."
    cp "$MANJIKAZE_DIR/app/security/yubikey/gpg.conf" ~/.gnupg/gpg.conf
    chmod 600 ~/.gnupg/gpg.conf

    # scdaemon: disable-ccid prevents repeated prompts for an already-inserted key
    echo "disable-ccid" > ~/.gnupg/scdaemon.conf
    chmod 600 ~/.gnupg/scdaemon.conf

    # gpg-agent: enable SSH support, use detected pinentry
    cat > ~/.gnupg/gpg-agent.conf <<AGENTCONF
enable-ssh-support
default-cache-ttl 43200
max-cache-ttl 43200
pinentry-program $pinentry_program
allow-loopback-pinentry
allow-preset-passphrase
AGENTCONF
    chmod 600 ~/.gnupg/gpg-agent.conf

    status "Starting GPG agent and initializing card reader..."
    export GPG_TTY=$(tty)
    gpg-connect-agent /bye > /dev/null 2>&1
    gpg-connect-agent "scd serialno" /bye > /dev/null 2>&1
}

configure_git_gpg() {
    local key_fp=$1
    status "Configuring Git to use GPG key for signing..."
    git config --global user.signingkey "$key_fp"
    git config --global commit.gpgsign true
    git config --global tag.gpgSign true
    git config --global gpg.program "$(command -v gpg)"
    git config --global gpg.format openpgp
}

configure_shell_env() {
    status "Configuring SSH to use GPG agent..."
    # Only add YubiKey IdentityFile if not already present
    mkdir -p ~/.ssh
    if [[ ! -f ~/.ssh/config ]] || ! grep -q "id_rsa_yubikey" ~/.ssh/config; then
        cat >> ~/.ssh/config << 'SSHCONF'

# YubiKey GPG-based SSH authentication
Host *
    IdentityFile ~/.ssh/id_rsa_yubikey.pub
SSHCONF
        chmod 600 ~/.ssh/config
    fi

    status "Configuring shell environment for GPG/SSH..."
    local plugin_dir="$HOME/.oh-my-zsh/custom/plugins/yubikey-gpg"
    mkdir -p "$plugin_dir"
    cat > "$plugin_dir/yubikey-gpg.plugin.zsh" << 'PLUGINCONF'
# YubiKey GPG agent for SSH
# Sets SSH_AUTH_SOCK to the gpg-agent SSH socket so that ssh, git, etc.
# use the GPG agent (and thus the YubiKey) for authentication.

export GPG_TTY=$(tty)
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

# Make sure gpg-agent is running
gpgconf --launch gpg-agent

# Update the TTY for the current session (important for pinentry)
gpg-connect-agent updatestartuptty /bye > /dev/null 2>&1
PLUGINCONF

    # NOTE: requires common.sh to be loaded
    if declare -f activate_zsh_plugin > /dev/null; then
        activate_zsh_plugin "yubikey-gpg"
    fi

    # Also export to systemd user environment so GUI apps pick it up
    systemctl --user import-environment SSH_AUTH_SOCK GPG_TTY 2>/dev/null || true

    # Start the gpg-agent sockets — they are socket-activated
    status "Starting gpg-agent socket activation..."
    systemctl --user start gpg-agent.socket gpg-agent-ssh.socket 2>/dev/null || true
}

configure_automatic_pin_entry() {
    local pin="${1:-}"

    echo ""
    local do_auto=$(gum confirm \
        "Enable automatic YubiKey PIN entry?

This will store your User PIN locally so you only need to touch the YubiKey
for daily operations (Git, SSH). The PIN is stored on your disk which is LUKS
encrypted, making it safe while the computer is turned off.

(Note: You will still need the Admin PIN for some setup operations.)" \
        --affirmative "Yes, enable" --negative "Skip" --default=true && echo "true" || echo "false")

    if [[ "$do_auto" == "true" ]]; then
        if [[ -z "$pin" ]]; then
            pin=$(gum input --password --header "Enter your YubiKey User PIN to store:")
        fi

        if [[ -n "$pin" ]]; then
            echo "$pin" > "$HOME/.gnupg/.yubikey-pin"
            chmod 600 "$HOME/.gnupg/.yubikey-pin"
            status "Automatic YubiKey PIN entry enabled."
        else
            status "No PIN entered, skipping automatic PIN entry."
        fi
    else
        rm -f "$HOME/.gnupg/.yubikey-pin"
        status "Skipped automatic PIN entry."
    fi
}
