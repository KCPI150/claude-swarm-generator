#!/bin/bash
# Hook: PostToolUse formatter for Python
# Runs ruff format on edited files (global)

if [ -n "$CLAUDE_FILE_PATHS" ]; then
  for file in $CLAUDE_FILE_PATHS; do
    if [[ "$file" =~ \.py$ ]]; then
      if command -v ruff &> /dev/null; then
        ruff format "$file" 2>/dev/null || true
      elif command -v black &> /dev/null; then
        black "$file" 2>/dev/null || true
      fi
    fi
  done
fi
