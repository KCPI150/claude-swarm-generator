#!/bin/bash
# Hook: PostToolUse linter for Python
# Runs ruff check --fix on edited files (global)

if [ -n "$CLAUDE_FILE_PATHS" ]; then
  for file in $CLAUDE_FILE_PATHS; do
    if [[ "$file" =~ \.py$ ]]; then
      if command -v ruff &> /dev/null; then
        ruff check --fix "$file" 2>/dev/null || true
      fi
    fi
  done
fi
