#!/bin/bash
# Claude Swarm Generator - Installer
# Installs swarm-generator, skills, and hooks for Claude Code

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "==================================="
echo "Claude Swarm Generator - Installer"
echo "==================================="
echo ""

# Check if jq is available (needed for settings.json merge)
if ! command -v jq &> /dev/null; then
    echo "Warning: jq not found. Hooks will not be auto-configured."
    echo "Install jq and re-run, or manually add hooks to ~/.claude/settings.json"
    JQ_AVAILABLE=false
else
    JQ_AVAILABLE=true
fi

# Step 1: Install swarm-generator
echo "[1/4] Installing swarm-generator..."
mkdir -p "$CLAUDE_DIR"
cp -r "$SCRIPT_DIR/swarm-generator" "$CLAUDE_DIR/"
echo "  ✓ Copied to ~/.claude/swarm-generator/"

# Step 2: Install skills
echo "[2/4] Installing skills..."
mkdir -p "$CLAUDE_DIR/skills"
cp -r "$SCRIPT_DIR/skills/deploy-swarm" "$CLAUDE_DIR/skills/"
cp -r "$SCRIPT_DIR/skills/cleanup-swarm" "$CLAUDE_DIR/skills/"
echo "  ✓ Installed deploy-swarm skill"
echo "  ✓ Installed cleanup-swarm skill"

# Step 3: Make hooks executable
echo "[3/4] Setting hook permissions..."
find "$CLAUDE_DIR/swarm-generator/hooks" -name "*.sh" -exec chmod +x {} \;
echo "  ✓ All hooks are now executable"

# Step 4: Configure hooks in settings.json
echo "[4/4] Configuring hooks..."

if [ "$JQ_AVAILABLE" = true ]; then
    SETTINGS_FILE="$CLAUDE_DIR/settings.json"
    HOOKS_DIR="$CLAUDE_DIR/swarm-generator/hooks"

    # Create settings.json if it doesn't exist
    if [ ! -f "$SETTINGS_FILE" ]; then
        echo '{}' > "$SETTINGS_FILE"
    fi

    # Backup existing settings
    cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup.$(date +%s)"

    # Create hooks configuration (v2.1.33+ format: matcher as object, hooks as objects)
    HOOKS_CONFIG=$(cat <<EOF
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": {"tools": ["Write", "Edit", "MultiEdit"]},
        "hooks": [{"type": "command", "command": "$HOOKS_DIR/formatters/ruff-format.sh"}]
      },
      {
        "matcher": {"tools": ["Write", "Edit", "MultiEdit"]},
        "hooks": [{"type": "command", "command": "$HOOKS_DIR/formatters/prettier.sh"}]
      },
      {
        "matcher": {"tools": ["Write", "Edit", "MultiEdit"]},
        "hooks": [{"type": "command", "command": "$HOOKS_DIR/validators/ruff-check.sh"}]
      }
    ],
    "PreToolUse": [
      {
        "matcher": {"tools": ["Write", "Edit"]},
        "hooks": [{"type": "command", "command": "$HOOKS_DIR/security/secrets-check.sh"}]
      },
      {
        "matcher": {"tools": ["Bash"]},
        "hooks": [{"type": "command", "command": "$HOOKS_DIR/security/block-dangerous.sh"}]
      }
    ]
  }
}
EOF
)

    # Merge hooks into settings (preserves existing settings)
    echo "$HOOKS_CONFIG" | jq -s '.[0] * .[1]' "$SETTINGS_FILE" - > "$SETTINGS_FILE.tmp"
    mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"

    echo "  ✓ Hooks configured in ~/.claude/settings.json"
    echo "  ✓ Backup saved to ~/.claude/settings.json.backup.*"
else
    echo "  ⚠ Skipped (jq not available)"
    echo ""
    echo "To manually configure hooks, add to ~/.claude/settings.json:"
    echo "  See README.md for hook configuration"
fi

echo ""
echo "==================================="
echo "Installation Complete!"
echo "==================================="
echo ""
echo "Installed:"
echo "  • ~/.claude/swarm-generator/ (stacks, templates, hooks)"
echo "  • ~/.claude/skills/deploy-swarm/"
echo "  • ~/.claude/skills/cleanup-swarm/"
echo ""
echo "Usage:"
echo "  /deploy-swarm              # Deploy a multi-agent swarm"
echo "  /deploy-swarm python       # Specify stack"
echo "  /cleanup-swarm             # Clean up after swarm"
echo ""
echo "Note: Restart Claude Code for hooks to take effect."
echo ""
