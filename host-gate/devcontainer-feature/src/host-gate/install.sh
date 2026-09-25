#!/bin/bash
set -euo pipefail

CONFIG_PATH="${CONFIGPATH:-/workspace/.devcontainer/host-gate.json}"
HOST_WS="${HOSTWORKSPACEFOLDER:-}"
CONTAINER_WS="${CONTAINERWORKSPACEFOLDER:-/workspace}"

cat > /usr/local/bin/host-gate-setup <<SETUP
#!/bin/bash
set -euo pipefail

ARCH=\$(uname -m)
case "\$ARCH" in
    x86_64)  ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    *)       echo "Unsupported architecture: \$ARCH" >&2; exit 1 ;;
esac

BINARY_NAME="host-gate-client-linux-\${ARCH}"

if [ ! -f "/usr/local/bin/host-gate-client" ]; then
    if [ -f "/var/run/host-gate/\${BINARY_NAME}" ]; then
        cp "/var/run/host-gate/\${BINARY_NAME}" /usr/local/bin/host-gate-client
        chmod 755 /usr/local/bin/host-gate-client
    else
        echo "host-gate: client binary not found at /var/run/host-gate/\${BINARY_NAME}" >&2
        echo "host-gate: ensure the host-gate daemon is running on the host" >&2
        exit 0
    fi
fi

exec host-gate-client setup --config "$CONFIG_PATH"
SETUP
chmod 755 /usr/local/bin/host-gate-setup

ENVFILE="/etc/profile.d/host-gate-env.sh"
echo "export HOST_GATE_HOST_WORKSPACE=\"$HOST_WS\"" > "$ENVFILE"
echo "export HOST_GATE_CONTAINER_WORKSPACE=\"$CONTAINER_WS\"" >> "$ENVFILE"

if [ -f /etc/bash.bashrc ]; then
    cat "$ENVFILE" >> /etc/bash.bashrc
fi
if [ -d /etc/zsh ]; then
    cat "$ENVFILE" >> /etc/zsh/zshenv 2>/dev/null || true
fi
