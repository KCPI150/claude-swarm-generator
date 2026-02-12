#!/bin/bash
# Hook: PreToolUse security check
# Blocks dangerous bash commands

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only check Bash commands
if [[ "$TOOL_NAME" != "Bash" ]]; then
  echo '{"decision": "allow"}'
  exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Literal patterns — matched with grep -F (no regex interpretation)
LITERAL_PATTERNS=(
  'rm -rf /'
  'rm -rf /*'
  'rm -rf ~'
  ':(){:|:&};:'
  '> /dev/sda'
  'chmod -R 777 /'
  'DROP TABLE'
  'DROP DATABASE'
  'TRUNCATE TABLE'
)

# Regex patterns — matched with grep -E
REGEX_PATTERNS=(
  'mkfs\.'
  'dd if=.* of=/dev/'
  '--force.*push.*main'
  '--force.*push.*master'
  'terraform destroy.*-auto-approve'
)

for pattern in "${LITERAL_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiF -- "$pattern"; then
    echo "{\"decision\": \"block\", \"reason\": \"Dangerous command blocked: $pattern\"}"
    exit 0
  fi
done

for pattern in "${REGEX_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE -- "$pattern"; then
    echo "{\"decision\": \"block\", \"reason\": \"Dangerous command blocked: $pattern\"}"
    exit 0
  fi
done

echo '{"decision": "allow"}'
