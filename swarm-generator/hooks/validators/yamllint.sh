#!/bin/bash
# Hook: PostToolUse linter for YAML
# Runs yamllint on edited files

if [ -n "$CLAUDE_FILE_PATHS" ]; then
  for file in $CLAUDE_FILE_PATHS; do
    if [[ "$file" =~ \.(yaml|yml)$ ]]; then
      if command -v yamllint &> /dev/null; then
        yamllint "$file" 2>/dev/null || true
      fi
    fi
  done
fi
