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

# Dangerous patterns
DANGEROUS_PATTERNS=(
  'rm -rf /'
  'rm -rf /*'
  'rm -rf ~'
  ':(){:|:&};:'
  'mkfs\.'
  'dd if=.* of=/dev/'
  '> /dev/sda'
  'chmod -R 777 /'
  'DROP TABLE'
  'DROP DATABASE'
  'TRUNCATE TABLE'
  '--force.*push.*main'
  '--force.*push.*master'
  'terraform destroy.*-auto-approve'
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE "$pattern"; then
    echo "{\"decision\": \"block\", \"reason\": \"Dangerous command pattern detected: $pattern\"}"
    exit 0
  fi
done

echo '{"decision": "allow"}'
