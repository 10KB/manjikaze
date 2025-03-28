enable_ssh_agent_service() {
    status "Configuring SSH agent..."

    # Stop any existing agents
    systemctl --user stop gpg-agent.socket gpg-agent.service gpg-agent-ssh.socket 2>/dev/null || true
    systemctl --user stop ssh-agent.service 2>/dev/null || true

    # Enable and start the ssh-agent service
    systemctl --user enable ssh-agent.service
    systemctl --user start ssh-agent.service

    # Source the updated environment
    export GPG_TTY=$(tty)
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
    gpgconf --launch gpg-agent
    gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1

    status "SSH agent has been configured. Please run 'source ~/.zshrc' or restart your terminal"

    # Verify the configuration
    if [[ -S "$SSH_AUTH_SOCK" ]]; then
        status "✅ SSH_AUTH_SOCK is properly set to: $SSH_AUTH_SOCK"
    else
        status "❌ SSH_AUTH_SOCK is not pointing to a valid socket: $SSH_AUTH_SOCK"
    fi
}
