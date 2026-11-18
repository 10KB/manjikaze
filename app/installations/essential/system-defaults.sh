source "$MANJIKAZE_DIR/lib/webcam-mic.sh"

FAST_SHUTDOWN_CONF="/etc/systemd/system.conf.d/10-faster-shutdown.conf"

# A service that doesn't stop holds up a shutdown for 5 seconds instead of 90.
configure_fast_shutdown() {
    if [[ -f "$FAST_SHUTDOWN_CONF" ]]; then
        status "Fast shutdown is already configured."
        return 0
    fi

    status "Configuring a 5 second shutdown timeout instead of 90 seconds..."
    sudo mkdir -p "$(dirname "$FAST_SHUTDOWN_CONF")"
    printf '[Manager]\nDefaultTimeoutStopSec=5s\n' | sudo tee "$FAST_SHUTDOWN_CONF" > /dev/null
    sudo systemctl daemon-reload
}

# Autologin has no password to unlock the login keyring with, so apps asked for it in every
# session. Full disk encryption already asks for a password at boot, and the keyring stayed
# unlocked all day, so with autologin the login keyring gets no password of its own.
configure_autologin_keyring() {
    local keyring_dir="$HOME/.local/share/keyrings"
    local login_keyring="$keyring_dir/login.keyring"

    if ! grep -Eq '^\s*AutomaticLoginEnable\s*=\s*[Tt]rue' /etc/gdm/custom.conf 2>/dev/null; then
        status "Autologin is off, so the login keyring keeps its password."
        return 0
    fi

    mkdir -p "$keyring_dir"
    chmod 700 "$keyring_dir"

    # A keyring without a password is a plain text file that starts with [keyring].
    if [[ -f "$login_keyring" ]] && head -n 1 "$login_keyring" | grep -q '^\[keyring\]'; then
        status "The login keyring has no password already."
    else
        if [[ -f "$login_keyring" ]]; then
            cp "$login_keyring" "$login_keyring.backup-$(date +%s)"
            status "Backed up the login keyring that has a password. Apps that stored a secret in it will ask you to sign in again once."
        fi

        cat > "$login_keyring" << EOF
[keyring]
display-name=Login
ctime=$(date +%s)
mtime=0
lock-on-idle=false
lock-after=false
EOF
        chmod 600 "$login_keyring"
        status "Created a login keyring without a password. Log out and back in to use it."
    fi

    echo "login" > "$keyring_dir/default"
    chmod 644 "$keyring_dir/default"
}

install() {
    configure_fast_shutdown

    if ! is_c920_mic_disabled; then
        disable_c920_mic
    fi

    configure_autologin_keyring

    source "$MANJIKAZE_DIR/app/security/updates/configure-update-checker.sh"

    source "$MANJIKAZE_DIR/app/security/updates/migration-notice.sh"
    install_migration_notice
}

uninstall() {
    if [[ -f "$FAST_SHUTDOWN_CONF" ]]; then
        sudo rm "$FAST_SHUTDOWN_CONF"
        sudo systemctl daemon-reload
        status "Shutdown uses the systemd timeout of 90 seconds again."
    fi

    if is_c920_mic_disabled; then
        enable_c920_mic
    fi

    source "$MANJIKAZE_DIR/app/security/updates/migration-notice.sh"
    remove_migration_notice

    status "To give the login keyring a password again, use Passwords and Keys (seahorse)."
}
