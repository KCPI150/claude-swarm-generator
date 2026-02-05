#!/bin/bash
# Hook: PostToolUse formatter for SQL
# Runs sqlfluff fix on edited files

if [ -n "$CLAUDE_FILE_PATHS" ]; then
  for file in $CLAUDE_FILE_PATHS; do
    if [[ "$file" =~ \.sql$ ]]; then
      if command -v sqlfluff &> /dev/null; then
        sqlfluff fix "$file" --force 2>/dev/null || true
      fi
    fi
  done
fi
