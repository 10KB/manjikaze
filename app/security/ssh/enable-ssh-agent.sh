enable_ssh_agent_service() {
    systemctl --user enable ssh-agent.service
    systemctl --user start ssh-agent.service
}