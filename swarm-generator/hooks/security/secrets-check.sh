#!/bin/bash
# Hook: PreToolUse security check
# Blocks commits/writes containing potential secrets

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only check Write/Edit operations
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then
  echo '{"decision": "allow"}'
  exit 0
fi

# Get the content being written
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // empty')

# Patterns that suggest secrets
PATTERNS=(
  'AKIA[0-9A-Z]{16}'                    # AWS Access Key
  'sk-[a-zA-Z0-9]{48}'                  # OpenAI API Key
  'sk_live_[a-zA-Z0-9]{24,}'            # Stripe Live Key
  'ghp_[a-zA-Z0-9]{36}'                 # GitHub Personal Token
  'github_pat_[a-zA-Z0-9_]{22,}'        # GitHub PAT
  'AIza[0-9A-Za-z_-]{35}'               # Google API Key
  'password\s*[:=]\s*["\x27][^"\x27]{8,}'  # Password assignments
  'secret\s*[:=]\s*["\x27][^"\x27]{8,}'    # Secret assignments
  'api[_-]?key\s*[:=]\s*["\x27][^"\x27]{16,}'  # API key assignments
)

for pattern in "${PATTERNS[@]}"; do
  if echo "$CONTENT" | grep -qiE "$pattern"; then
    echo '{"decision": "block", "reason": "Potential secret detected. Review the content before committing."}'
    exit 0
  fi
done

echo '{"decision": "allow"}'
