# Claude Code Hooks Format (v2.1.33+)

## Correct Format

As of Claude Code v2.1.33 (verified 2026-02-06):

### Matcher
- **Type:** String (regex pattern)
- **Examples:** `"Write|Edit"`, `"Bash"`, `"Write|Edit|MultiEdit"`
- **Match all:** Omit the field entirely, or use `""` or `"*"`

### Hooks Array
- **Type:** Array of objects
- **Format:** `[{"type": "command", "command": "path/to/script"}]`

## What Changed in v2.1.33

- ✅ **Hooks array** format changed to use objects: `[{"type": "command", "command": "..."}]`
- ❌ **Matchers** remain strings (regex), NOT objects

## Example

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {"type": "command", "command": "/path/to/script.sh"}
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {"type": "command", "command": "/path/to/validator.sh"}
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {"type": "command", "command": "/path/to/notify.sh"}
        ]
      }
    ]
  }
}
```

## Common Mistake

❌ **Incorrect** (object matcher):
```json
{
  "matcher": {"tools": ["Write", "Edit"]},
  "hooks": [{"type": "command", "command": "script.sh"}]
}
```

✅ **Correct** (string matcher):
```json
{
  "matcher": "Write|Edit",
  "hooks": [{"type": "command", "command": "script.sh"}]
}
```

## Reference

- Official docs: https://code.claude.com/docs/en/hooks
- See examples in `hooks/` directory
