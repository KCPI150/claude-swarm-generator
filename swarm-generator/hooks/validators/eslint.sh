#!/bin/bash
# Hook: PostToolUse linter for TypeScript/Angular
# Runs eslint --fix on edited files (global)

if [ -n "$CLAUDE_FILE_PATHS" ]; then
  for file in $CLAUDE_FILE_PATHS; do
    if [[ "$file" =~ \.(ts|tsx|js|jsx)$ ]]; then
      if command -v npx &> /dev/null; then
        npx eslint --fix "$file" 2>/dev/null || true
      fi
    fi
  done
fi
