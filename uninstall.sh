#!/bin/bash
# Claude Swarm Generator - Uninstaller

set -e

CLAUDE_DIR="$HOME/.claude"

echo "Removing Claude Swarm Generator..."

# Remove swarm-generator
rm -rf "$CLAUDE_DIR/swarm-generator"
echo "  ✓ Removed ~/.claude/swarm-generator/"

# Remove skills
rm -rf "$CLAUDE_DIR/skills/deploy-swarm"
rm -rf "$CLAUDE_DIR/skills/cleanup-swarm"
echo "  ✓ Removed skills"

echo ""
echo "Uninstall complete."
echo ""
echo "Note: Hooks in ~/.claude/settings.json were NOT removed."
echo "Edit that file manually if you want to remove hook configurations."
