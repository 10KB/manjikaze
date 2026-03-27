#!/bin/bash
set -e

FEATURE_SRC="$(cd "$(dirname "$0")/../devcontainer-feature/src/host-gate" && pwd)"
TARGET_DIR="${1:-.}/.devcontainer"

if [ ! -d "$TARGET_DIR" ]; then
    echo "No .devcontainer/ directory found at $(cd "${1:-.}" && pwd)" >&2
    echo "Usage: $0 [project-path]" >&2
    exit 1
fi

mkdir -p "$TARGET_DIR/host-gate"
cp "$FEATURE_SRC/devcontainer-feature.json" "$TARGET_DIR/host-gate/"
cp "$FEATURE_SRC/install.sh" "$TARGET_DIR/host-gate/"
chmod +x "$TARGET_DIR/host-gate/install.sh"

echo "Host gate feature copied to $TARGET_DIR/host-gate/"
echo ""
echo "Add to your devcontainer.json:"
echo '  "features": {'
echo '    "./host-gate": {}'
echo '  }'

if [ ! -f "$TARGET_DIR/host-gate.json" ]; then
    cat > "$TARGET_DIR/host-gate.json" <<'EOF'
{
  "rules": [
    {
      "match": ["git", "push"],
      "execution": "proxy",
      "approval": "popup"
    }
  ]
}
EOF
    echo ""
    echo "Created default container config at $TARGET_DIR/host-gate.json"
fi
