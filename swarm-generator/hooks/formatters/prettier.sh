#!/bin/bash
# Hook: PostToolUse formatter for TypeScript/Angular/YAML/JSON
# Runs prettier on edited files (global - no package.json required)

if [ -n "$CLAUDE_FILE_PATHS" ]; then
  for file in $CLAUDE_FILE_PATHS; do
    if [[ "$file" =~ \.(ts|tsx|js|jsx|html|scss|css|json|yaml|yml|md)$ ]]; then
      if command -v npx &> /dev/null; then
        npx prettier --write "$file" 2>/dev/null || true
      fi
    fi
  done
fi
