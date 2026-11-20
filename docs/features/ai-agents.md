# AI Agents

Manjikaze installs the AI coding agents for the terminal in one way: with [mise](https://mise.jdx.dev), like the other [tools installed with mise](../maintenance/updates.md#tools-installed-with-mise).

Choose them under **Setup > Choose AI agents**. The agents you have start out selected: select one to install it, deselect one to remove it. Escape leaves everything as it is. Choosing an agent you already have brings it up to date and finishes anything an earlier install left behind.

| Agent             | Command                 | From                                                                |
| ----------------- | ----------------------- | ------------------------------------------------------------------- |
| `claude-code`     | `claude`                | Anthropic's Claude Code                                             |
| `codex`           | `codex`                 | OpenAI's Codex                                                      |
| `antigravity-cli` | `agy`                   | Google's Antigravity CLI, which works without the `antigravity` app |
| `cursor-cli`      | `agent`, `cursor-agent` | The Cursor CLI, which works without the `cursor` editor            |

Each agent is a script in `app/installations/ai-agents/` with the version file `configs/mise/<tool>.toml`. To add an agent, add both.

## Updates

Every [update](../maintenance/updates.md) upgrades the agents to the newest release that is at least a day old. They release almost every day, so Manjikaze doesn't pin a version. Cursor publishes only its newest release, so the Cursor CLI gets that one, however new.

Need a release right away, for example for a new model? Upgrade the agent yourself without the waiting time, here Claude Code:

```bash
MISE_MINIMUM_RELEASE_AGE=0 mise upgrade claude
```

The next update keeps that version: it only ever moves to newer releases.

The agents don't update themselves, so mise stays in charge of the version:

- **Claude Code:** `/etc/claude-code/managed-settings.d/manjikaze-mise.json` sets `DISABLE_AUTOUPDATER` and `DISABLE_UPDATES` for every Claude Code on the machine. `claude update` doesn't work then; run `manjikaze update`.
- **Codex:** `/etc/codex/config.toml` sets `check_for_update_on_startup = false`. Your own `~/.codex/config.toml` can override that. When `/etc/codex/config.toml` already exists with other settings, Manjikaze leaves it alone and tells you to add the setting.
- **Antigravity CLI:** agy replaces its own program when it updates, also inside mise's installs. `~/.config/environment.d/50-antigravity-cli.conf` sets `AGY_CLI_DISABLE_AUTO_UPDATE=true` from the next login. Log out and back in after installing it.
- **Cursor CLI:** its settings, `cli-config.json`, put it on the `static` channel, which doesn't update. The file is in `$XDG_CONFIG_HOME/cursor` when that variable is set, as in a desktop session, and otherwise in `~/.cursor`. Removing the agent takes it off that channel again.

The Cursor CLI comes with its own Node.js and ripgrep. Only `agent` and `cursor-agent` go on your `PATH`, so they don't take the place of yours.

## Switching from the Vendor's Installer

If you installed an agent with its vendor's installer, choosing it in Manjikaze replaces that copy once mise has installed the agent:

- Claude Code: the link `~/.local/bin/claude` and `~/.local/share/claude`
- Codex: the link `~/.local/bin/codex` and `~/.codex/packages/standalone`
- Antigravity CLI: `~/.local/bin/agy` and the `agy.*.old` files of its own updates
- Cursor CLI: the links `~/.local/bin/agent` and `~/.local/bin/cursor-agent`, and `~/.local/share/cursor-agent/versions`

Your settings, logins and session history stay: they're in `~/.claude` and `~/.claude.json`, the rest of `~/.codex`, `~/.gemini`, `~/.cursor` and the Cursor CLI's settings. `claude --resume` and `codex resume` still find your earlier sessions.

When the vendor's copy is newer than the newest release that is a day old, the switch takes you a release back until the next update. Upgrade right away, as above, to stay on the newer one.

An agent that is still running keeps its copy, and Manjikaze says so. Close the agent and choose it again to remove the copy.

The Codex app-server daemon, which Codex starts for remote control, has a copy of its own in `~/.codex/packages/app-server-daemon` that Codex keeps up to date. Manjikaze leaves it alone.
