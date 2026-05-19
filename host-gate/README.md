# Host Gate

Secure container-to-host command approval system. Intercepts configured commands inside Docker containers and requires host-side human approval (desktop popup) or physical presence (YubiKey touch) before execution.

## How It Works

1. Commands inside the container are intercepted by wrapper scripts
2. The client sends an HMAC-signed request to the host daemon over a Unix socket
3. The daemon checks the host security policy, shows a desktop popup, and optionally requires YubiKey touch
4. If approved, the command either executes on the host (proxy mode) or the container proceeds locally (local mode)

## Installation

Host Gate is installed as a manjikaze optional app:

```bash
manjikaze  # then select "Install optional apps" -> "host-gate"
```

This builds from source, installs binaries, sets up the systemd user service, and creates a default host policy config.

### Manual Installation

```bash
cd host-gate
make build
sudo install -m 755 bin/host-gate-daemon /usr/local/bin/
sudo install -m 755 bin/host-gate-client-linux-amd64 /usr/local/bin/host-gate-client

mkdir -p ~/.config/host-gate
cp configs/default-policy.json ~/.config/host-gate/policy.json

mkdir -p ~/.config/systemd/user
cp systemd/host-gate.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now host-gate.service
```

## Configuration

### Host Policy (`~/.config/host-gate/policy.json`)

The host policy is the security boundary. It controls which commands are allowed and enforces minimum approval levels. The container cannot weaken these settings.

```json
{
  "defaultPolicy": "deny",
  "rules": [
    {
      "match": ["git", "push"],
      "allow": true,
      "minApproval": "popup",
      "minExecution": "proxy"
    },
    {
      "match": ["git", "push", "--force"],
      "allow": true,
      "minApproval": "yubikey"
    },
    {
      "match": ["kubectl", "delete"],
      "allow": false
    }
  ]
}
```

- `defaultPolicy`: `"deny"` (safe default) or `"allow"`
- `rules[].match`: Command prefix to match (longest prefix wins)
- `rules[].allow`: Whether this command is permitted at all
- `rules[].minApproval`: Minimum approval mode (`"popup"` or `"yubikey"`)
- `rules[].minExecution`: Minimum execution mode (`"local"` or `"proxy"`)

When both the container and host specify modes, the **most restrictive** option wins per dimension.

### Container Config (`.devcontainer/host-gate.json`)

Per-project config defining which commands to gate:

```json
{
  "rules": [
    {
      "match": ["git", "push"],
      "execution": "proxy",
      "approval": "popup"
    },
    {
      "match": ["npm", "publish"],
      "execution": "proxy",
      "approval": "yubikey"
    }
  ]
}
```

### Daemon Flags

Set in the systemd unit file or via CLI:

- `--socket-dir`: Socket directory (default: `$XDG_RUNTIME_DIR/host-gate`)
- `--host-config`: Host policy config path (default: `~/.config/host-gate/policy.json`)
- `--approval-timeout`: Popup timeout (default: `60s`)
- `--yubikey-slot`: YubiKey OTP slot (default: `2`)
- `--yubikey-timeout`: YubiKey touch timeout (default: `30s`)
- `--workspace-map`: Container-to-host path mapping (e.g., `/workspace:/home/user/project`)
- `--log-level`: Log level (default: `info`)

Edit `~/.config/systemd/user/host-gate.service` to add workspace maps:

```ini
ExecStart=/usr/local/bin/host-gate-daemon \
    --workspace-map=/workspace:/home/user/my-project
```

Then reload: `systemctl --user daemon-reload && systemctl --user restart host-gate`

## Dev Container Feature

Local devcontainer features must live inside `.devcontainer/`. Use the init script to set up a project:

```bash
~/.manjikaze/host-gate/scripts/init-project.sh /path/to/your/project
```

This copies the feature files and creates a default container config. Then add to your `devcontainer.json`:

```json
{
  "features": {
    "./host-gate": {}
  }
}
```

To customize the container config path:

```json
{
  "features": {
    "./host-gate": {
      "configPath": "/workspace/.devcontainer/host-gate.json"
    }
  }
}
```

For docker-compose setups, you may also need to add the volume mount explicitly:

```yaml
volumes:
  - ${XDG_RUNTIME_DIR}/host-gate:/var/run/host-gate:ro
```

## YubiKey Setup

Host Gate uses YubiKey HMAC-SHA1 Challenge-Response for physical presence verification. The `yubikey-manager` package is already installed as an essential manjikaze package.

One-time slot configuration:

```bash
./scripts/configure-yubikey-slot.sh
# or manually:
ykman otp chalresp --touch --generate 2
```

This configures OTP slot 2 with a random key and requires physical touch.

## Verification

```bash
# Check daemon status
systemctl --user status host-gate

# Health check
curl --unix-socket $XDG_RUNTIME_DIR/host-gate/gate.sock http://host-gate/health
```

## Execution Modes

| Execution | Approval | Use Case |
|-----------|----------|----------|
| `proxy` | `popup` | `git push` -- needs host SSH key |
| `proxy` | `yubikey` | `npm publish` -- needs host token + physical presence |
| `local` | `popup` | Destructive commands -- runs in container, needs approval |
| `local` | `yubikey` | `kubectl delete` -- needs physical presence |

## Development

```bash
cd host-gate
make test    # Run all tests
make build   # Build binaries
make lint    # Run linter (requires golangci-lint)
```
