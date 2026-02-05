#!/bin/bash
# Hook: PostToolUse formatter for Kotlin
# Runs ktlint on edited files

if [ -n "$CLAUDE_FILE_PATHS" ]; then
  for file in $CLAUDE_FILE_PATHS; do
    if [[ "$file" =~ \.kt$ ]] || [[ "$file" =~ \.kts$ ]]; then
      if command -v ktlint &> /dev/null; then
        ktlint --format "$file" 2>/dev/null || true
      elif [ -f "gradlew" ]; then
        ./gradlew ktlintFormat 2>/dev/null || true
      fi
    fi
  done
fi
