#!/bin/bash
# Hook: PostToolUse formatter for Terraform
# Runs terraform fmt on edited files

if [ -n "$CLAUDE_FILE_PATHS" ]; then
  for file in $CLAUDE_FILE_PATHS; do
    if [[ "$file" =~ \.tf$ ]]; then
      if command -v terraform &> /dev/null; then
        terraform fmt "$file" 2>/dev/null || true
      fi
    fi
  done
fi
