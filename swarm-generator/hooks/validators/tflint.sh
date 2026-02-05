#!/bin/bash
# Hook: PostToolUse linter for Terraform
# Runs tflint on edited files

if [ -n "$CLAUDE_FILE_PATHS" ]; then
  for file in $CLAUDE_FILE_PATHS; do
    if [[ "$file" =~ \.tf$ ]]; then
      dir=$(dirname "$file")
      if command -v tflint &> /dev/null; then
        tflint --chdir="$dir" 2>/dev/null || true
      fi
    fi
  done
fi
