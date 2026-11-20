#!/bin/bash
# Choosing AI agents, and installing them with mise in place of the copies that their vendors'
# installers made.
set -euo pipefail

source "$(dirname "$0")/lib.sh"

unset CURSOR_CONFIG_DIR
# Not GNOME, so disable_sleep leaves the real desktop's settings alone.
export XDG_CURRENT_DESKTOP=""
MANJIKAZE_DIR="$ROOT"
source "$ROOT/lib/common.sh"

INSTALLS="$HOME/.local/share/mise/installs"

# mise installs version 1.0.0 of a tool with its program in bin. The tool is named after its
# program, except for claude-code's claude.
cat > "$TEST_TMP/bin/mise" << 'EOF'
#!/bin/bash
echo "mise $*${MISE_MINIMUM_RELEASE_AGE:+ (age $MISE_MINIMUM_RELEASE_AGE)}" >> "$TEST_TMP/mise.calls"
installs="$HOME/.local/share/mise/installs"
tool=${2%@*}
case "$1" in
    install)
        mkdir -p "$installs/$tool/1.0.0/bin"
        printf '#!/bin/bash\n' > "$installs/$tool/1.0.0/bin/$tool"
        if [[ $tool == cursor-agent ]]; then
            ln -sfn cursor-agent "$installs/$tool/1.0.0/bin/agent"
        fi
        chmod +x "$installs/$tool/1.0.0/bin/$tool"
        ln -sfn ./1.0.0 "$installs/$tool/latest"
        ;;
    bin-paths) echo "$installs/$tool/latest/bin" ;;
esac
EOF
# Without GUM_CHOICE, choose acts as if Escape was pressed.
cat > "$TEST_TMP/bin/gum" << 'EOF'
#!/bin/bash
echo "$*" >> "$TEST_TMP/gum.calls"
case "$1" in
    log) echo "${*: -1}" >&2 ;;
    choose) [[ -n ${GUM_CHOICE+set} ]] || exit 130; printf '%s\n' $GUM_CHOICE ;;
esac
EOF
for command in systemctl gsettings; do
    printf '#!/bin/bash\necho "%s $*" >> "$TEST_TMP/%s.calls"\n' "$command" "$command" > "$TEST_TMP/bin/$command"
done
chmod +x "$TEST_TMP"/bin/{mise,gum,systemctl,gsettings}

new_home() {
    rm -rf "$HOME" "$TEST_TMP"/*.calls
    mkdir -p "$HOME/.local/bin"
    unset GUM_CHOICE
}

links_to_mise() {
    [[ $(readlink "$HOME/.local/bin/$1") == "$INSTALLS/$2/latest/bin/$1" ]]
}

managed() {
    [[ -f $HOME/.config/mise/conf.d/manjikaze-$1.toml ]]
}

choose_agents() {
    run source "$ROOT/app/installations/choose-ai-agents.sh"
}

new_home
mkdir -p "$HOME/.local/share/claude/versions"
printf '#!/bin/bash\n' > "$HOME/.local/share/claude/versions/2.1.329"
ln -s "$HOME/.local/share/claude/versions/2.1.329" "$HOME/.local/bin/claude"
source "$ROOT/app/installations/ai-agents/claude-code.sh"
run install
[[ $exit_code -eq 0 ]] || fail "installing Claude Code succeeds" "$(errors)"
grep -q '^mise install claude@latest (age 24h)$' "$TEST_TMP/mise.calls" ||
    fail "mise installs the newest release that is a day old" "$(cat "$TEST_TMP/mise.calls")"
links_to_mise claude claude || fail "the claude in ~/.local/bin links to mise's latest version" "$(ls -l "$HOME/.local/bin")"
[[ ! -e $HOME/.local/share/claude ]] || fail "the copy of the native installer is removed"
grep -q "managed-settings.d/manjikaze-mise.json" "$TEST_TMP/sudo.calls" ||
    fail "Claude Code's own updates are switched off" "$(cat "$TEST_TMP/sudo.calls")"
pass "Claude Code from mise replaces the native install"

new_home
mkdir -p "$HOME/.codex/packages/standalone/current/bin"
cp "$(command -v sleep)" "$HOME/.codex/packages/standalone/current/bin/codex"
ln -s "$HOME/.codex/packages/standalone/current/bin/codex" "$HOME/.local/bin/codex"
"$HOME/.codex/packages/standalone/current/bin/codex" 30 &
running=$!
source "$ROOT/app/installations/ai-agents/codex.sh"
run install
links_to_mise codex codex || fail "the link moves to mise while the old copy runs" "$(ls -l "$HOME/.local/bin")"
[[ -d $HOME/.codex/packages/standalone ]] || fail "a copy that a process runs from stays"
grep -q "codex still runs from" "$TEST_TMP/err" || fail "the install says why the copy stays" "$(errors)"
kill "$running"
wait "$running" 2> /dev/null || true
run install
[[ ! -e $HOME/.codex/packages/standalone ]] || fail "installing again removes the copy once nothing runs from it"
links_to_mise codex codex || fail "installing again keeps the link to mise" "$(ls -l "$HOME/.local/bin")"
pass "a copy that still runs stays until the next install"

new_home
printf '#!/bin/bash\n' > "$HOME/.local/bin/agy"
printf '#!/bin/bash\n' > "$HOME/.local/bin/agy.1234.old"
chmod +x "$HOME/.local/bin/agy" "$HOME/.local/bin/agy.1234.old"
source "$ROOT/app/installations/ai-agents/antigravity-cli.sh"
run install
[[ $exit_code -eq 0 ]] || fail "installing the Antigravity CLI succeeds" "$(errors)"
links_to_mise agy agy || fail "the copied agy makes way for a link to mise" "$(ls -l "$HOME/.local/bin")"
[[ ! -e $HOME/.local/bin/agy.1234.old ]] || fail "the old copies of agy's own updates are removed"
grep -qx "AGY_CLI_DISABLE_AUTO_UPDATE=true" "$HOME/.config/environment.d/50-antigravity-cli.conf" ||
    fail "agy's own updates are switched off for the session"
run install
links_to_mise agy agy || fail "installing agy again keeps the link to mise" "$(ls -l "$HOME/.local/bin")"
pass "the Antigravity CLI from mise replaces the copied agy and doesn't update itself"

new_home
mkdir -p "$HOME/.local/share/cursor-agent/versions/2026.10.01-e373342" "$HOME/.local/share/cursor-agent/logs" "$HOME/.cursor"
printf '#!/bin/bash\n' > "$HOME/.local/share/cursor-agent/versions/2026.10.01-e373342/cursor-agent"
for program in agent cursor-agent; do
    ln -s "$HOME/.local/share/cursor-agent/versions/2026.10.01-e373342/cursor-agent" "$HOME/.local/bin/$program"
done
echo '{"version": 1, "editor": {"vimMode": true}}' > "$HOME/.cursor/cli-config.json"
source "$ROOT/app/installations/ai-agents/cursor-cli.sh"
run install
[[ $exit_code -eq 0 ]] || fail "installing the Cursor CLI succeeds" "$(errors)"
links_to_mise cursor-agent cursor-agent && links_to_mise agent cursor-agent ||
    fail "agent and cursor-agent link to mise" "$(ls -l "$HOME/.local/bin")"
[[ ! -e $HOME/.local/share/cursor-agent/versions && -d $HOME/.local/share/cursor-agent/logs ]] ||
    fail "only the versions of the Cursor installer are removed" "$(ls -R "$HOME/.local/share/cursor-agent" 2>&1)"
jq -e '.channel == "static" and .editor.vimMode == true' "$HOME/.cursor/cli-config.json" > /dev/null ||
    fail "the Cursor CLI's own updates are switched off, and its settings stay" "$(cat "$HOME/.cursor/cli-config.json")"
run uninstall
jq -e 'has("channel") | not' "$HOME/.cursor/cli-config.json" > /dev/null ||
    fail "removing the Cursor CLI lets it update itself again" "$(cat "$HOME/.cursor/cli-config.json")"
pass "the Cursor CLI from mise replaces the vendor's versions and stays on the static channel"

new_home
printf '#!/bin/bash\n' > "$HOME/.local/bin/claude"
source "$ROOT/app/installations/ai-agents/claude-code.sh"
run install
[[ ! -L $HOME/.local/bin/claude ]] || fail "a claude in ~/.local/bin that no installer made stays"
pass "a program of your own in ~/.local/bin stays"

new_home
export GUM_CHOICE="claude-code codex"
choose_agents
[[ $exit_code -eq 0 ]] || fail "choosing AI agents succeeds" "$(errors)"
managed claude && managed codex || fail "the chosen agents are installed" "$(ls "$HOME/.config/mise/conf.d")"
! managed agy && ! managed cursor-agent || fail "only the chosen agents are installed"
export GUM_CHOICE="codex"
choose_agents
grep -q -- "--selected claude-code,codex" "$TEST_TMP/gum.calls" ||
    fail "the installed agents start out selected" "$(cat "$TEST_TMP/gum.calls")"
! managed claude && managed codex || fail "deselecting an agent removes it" "$(ls "$HOME/.config/mise/conf.d")"
pass "the AI agents menu installs what you select and removes what you deselect"

unset GUM_CHOICE
choose_agents
managed codex || fail "escape leaves the AI agents alone"
export GUM_CHOICE=""
choose_agents
! managed codex || fail "selecting no agent removes them all"
pass "escape changes nothing, an empty selection removes every agent"
