source "$MANJIKAZE_DIR/lib/yubikey-pam.sh"

setup_yubikey_pam=$(gum confirm "Do you want to unlock, use sudo and approve polkit prompts with your YubiKey and its PIN?" --affirmative "Yes" --negative "No" --default=false && echo "true" || echo "false")

if [[ $setup_yubikey_pam == "true" ]]; then
    if yubikey_pam_configure; then
        yubikey_pam_remove_legacy || status "Removing touch-only unlock failed; see the messages above."
        echo "Keep this terminal open. In a new terminal, test 'sudo -k; sudo true' and 'pkexec true' before you lock the screen."
        echo "Without the YubiKey inserted, your password works as before."
    else
        status "YubiKey unlock was not set up. Your password keeps working."
    fi
fi
