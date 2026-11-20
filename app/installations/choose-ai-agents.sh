AI_AGENTS_DIR="$MANJIKAZE_DIR/app/installations/ai-agents"

# An agent counts as installed while Manjikaze manages its mise tool.
agent_installed() {
    local tool
    tool=$(source "$AI_AGENTS_DIR/$1.sh" && echo "$AGENT_TOOL")
    [[ -f "$MISE_MANAGED_DIR/manjikaze-$tool.toml" ]]
}

available_agents=()
installed_agents=()
for agent_file in "$AI_AGENTS_DIR"/*.sh; do
    agent=$(basename "$agent_file" .sh)
    available_agents+=("$agent")
    if agent_installed "$agent"; then
        installed_agents+=("$agent")
    fi
done

choose_options=(--no-limit --header "Choose your AI agents. Deselect one to remove it.")
if [[ ${#installed_agents[@]} -gt 0 ]]; then
    choose_options+=(--selected "$(IFS=,; echo "${installed_agents[*]}")")
fi

# Escape cancels. Enter without any agent selected removes them all.
if ! chosen=$(gum choose "${choose_options[@]}" "${available_agents[@]}"); then
    status "AI agents unchanged."
    return 0
fi
readarray -t chosen_agents < <(printf '%s\n' "$chosen" | grep -v '^$' || true)

removed_agents=()
for agent in "${installed_agents[@]}"; do
    if ! printf '%s\n' "${chosen_agents[@]}" | grep -qxF "$agent"; then
        removed_agents+=("$agent")
    fi
done

if [[ ${#chosen_agents[@]} -eq 0 && ${#removed_agents[@]} -eq 0 ]]; then
    status "No AI agents chosen."
    return 0
fi

if [[ ${#chosen_agents[@]} -gt 0 ]]; then
    echo "These AI agents will be installed, or brought up to date:"
    printf "  - %s\n" "${chosen_agents[@]}"
fi
if [[ ${#removed_agents[@]} -gt 0 ]]; then
    echo "These AI agents will be removed:"
    printf "  - %s\n" "${removed_agents[@]}"
fi

if ! gum confirm "Do you want to proceed?"; then
    status "AI agents unchanged."
    return 0
fi

disable_sleep
failed_agents=()
for agent in "${chosen_agents[@]}"; do
    source "$AI_AGENTS_DIR/$agent.sh"
    install || failed_agents+=("$agent")
done
for agent in "${removed_agents[@]}"; do
    source "$AI_AGENTS_DIR/$agent.sh"
    uninstall || failed_agents+=("$agent")
done
enable_sleep

if [[ ${#failed_agents[@]} -gt 0 ]]; then
    status "These AI agents failed: ${failed_agents[*]}. See the messages above."
    return 1
fi
status "AI agents updated."
