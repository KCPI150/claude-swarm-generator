---
name: deploy-swarm
description: "Generate and deploy multi-agent swarms with hooks. Auto-detects tech stack, selects templates, installs hooks, spawns teammates. Use for dev pipelines, code review, refactoring workflows."
---

# Deploy Swarm (v2)

Generate and deploy a complete multi-agent swarm with appropriate hooks.

**v2 Changes:**
- Better project detection (checks actual files)
- Leader-managed task updates (subagents can't update tasks)
- Sequential agent spawning with completion tracking
- **Proper hook verification and creation**

## Usage

```
/deploy-swarm                              # Interactive
/deploy-swarm <stack>                      # Explicit stack
/deploy-swarm <stack> <template>           # Explicit stack and template
/deploy-swarm <stack> <template> "desc"    # Full specification
```

---

## Step 1: Detect Project Stack

**Check actual files in project:**

```bash
ls *.py 2>/dev/null | head -1           # Python?
ls angular.json 2>/dev/null             # Angular?
ls *.kt 2>/dev/null | head -1           # Kotlin?
ls *.tf 2>/dev/null | head -1           # Terraform?
ls *.sql 2>/dev/null | head -1          # SQL?
ls dags/*.py 2>/dev/null | head -1      # Airflow?
ls *.yaml *.yml 2>/dev/null | head -1   # YAML?
```

**Confirm with user before proceeding.**

---

## Step 2: Load Stack and Template Configs

```bash
# Read stack config
cat ~/.claude/swarm-generator/stacks/{STACK}.json

# Read template config
cat ~/.claude/swarm-generator/templates/{TEMPLATE}.json
```

---

## Step 3: Hook Verification and Creation (CRITICAL)

**For each teammate in the template, verify their required hooks exist.**

### 3a. Build Hook Requirements Map

From template, each teammate has `required_hooks`. Map these to actual scripts:

| Teammate | Required Hook | Stack: python | Stack: angular |
|----------|---------------|---------------|----------------|
| builder | format-on-save | ruff-format.sh | prettier.sh |
| linter | formatter | ruff-format.sh | prettier.sh |
| linter | linter | ruff-check.sh | eslint.sh |
| validator | test-runner | (run pytest) | (run ng test) |
| security | secrets-check | secrets-check.sh | secrets-check.sh |

### 3b. Verify Each Hook Exists

```bash
# Check if hook script exists
HOOKS_DIR="$HOME/.claude/swarm-generator/hooks"

# For each required hook, verify file exists
ls "$HOOKS_DIR/formatters/ruff-format.sh" 2>/dev/null || echo "MISSING: ruff-format.sh"
ls "$HOOKS_DIR/validators/ruff-check.sh" 2>/dev/null || echo "MISSING: ruff-check.sh"
ls "$HOOKS_DIR/security/secrets-check.sh" 2>/dev/null || echo "MISSING: secrets-check.sh"
```

### 3c. Create Missing Hooks

**If a hook is missing, CREATE IT:**

```bash
# Example: Create missing formatter hook
cat > "$HOOKS_DIR/formatters/NEW_FORMATTER.sh" << 'EOF'
#!/bin/bash
# Hook: PostToolUse formatter for LANGUAGE
if [ -n "$CLAUDE_FILE_PATHS" ]; then
  for file in $CLAUDE_FILE_PATHS; do
    if [[ "$file" =~ \.EXT$ ]]; then
      COMMAND "$file" 2>/dev/null || true
    fi
  done
fi
EOF
chmod +x "$HOOKS_DIR/formatters/NEW_FORMATTER.sh"
```

### 3d. Report Hook Status

```
Hook Verification:
✓ ruff-format.sh exists
✓ ruff-check.sh exists
✓ secrets-check.sh exists
✓ block-dangerous.sh exists

All required hooks available.
```

OR if created:

```
Hook Verification:
✓ ruff-format.sh exists
✗ custom-linter.sh MISSING → Created
✓ secrets-check.sh exists

Created 1 new hook.
```

---

## Step 4: Install Hooks to Project

### 4a. Build hooks configuration

**Map stack to hook scripts with ABSOLUTE paths:**

```javascript
const HOOKS_DIR = "/Users/USERNAME/.claude/swarm-generator/hooks"

// Stack-specific mapping
const hookConfig = {
  python: {
    formatter: `${HOOKS_DIR}/formatters/ruff-format.sh`,
    linter: `${HOOKS_DIR}/validators/ruff-check.sh`
  },
  angular: {
    formatter: `${HOOKS_DIR}/formatters/prettier.sh`,
    linter: `${HOOKS_DIR}/validators/eslint.sh`
  },
  // ... other stacks
}
```

### 4b. Generate settings.json

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": ["/absolute/path/to/formatter.sh"]
      },
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": ["/absolute/path/to/linter.sh"]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": ["/absolute/path/to/secrets-check.sh"]
      },
      {
        "matcher": "Bash",
        "hooks": ["/absolute/path/to/block-dangerous.sh"]
      }
    ]
  }
}
```

### 4c. Install to project

```bash
mkdir -p .claude
# Write or merge into .claude/settings.json
```

---

## Step 5: Create Tasks

Create tasks from template with dependencies:

```javascript
TaskCreate({ subject: "Build: <feature>", description: "...", activeForm: "Building..." })
TaskCreate({ subject: "Lint: Format and verify", ... })
TaskUpdate({ taskId: "2", addBlockedBy: ["1"] })
// etc.
```

---

## Step 6: Sequential Agent Spawning

**IMPORTANT:** Subagents don't have TaskList/TaskUpdate tools.
Leader manages all task state.

**For each task in order:**

```javascript
// 1. Mark task in_progress
TaskUpdate({ taskId: "N", status: "in_progress" })

// 2. Spawn agent and WAIT (not background)
Task({
  description: "Agent name",
  subagent_type: "general-purpose",
  prompt: AGENT_PROMPT_WITH_HOOK_AWARENESS,
  run_in_background: false  // WAIT for completion
})

// 3. Read result, mark complete
TaskUpdate({ taskId: "N", status: "completed" })

// 4. Report progress to user
// "[1/4] Builder completed ✓"
```

---

## Step 7: Agent Prompts with Hook Awareness

**Every agent prompt MUST include hook awareness section:**

```
You are {ROLE} in a {TEMPLATE} swarm.

## Your Task
{TASK_DESCRIPTION}

## Instructions
{ROLE_SPECIFIC_INSTRUCTIONS}

## Hook Awareness
These hooks run AUTOMATICALLY after your edits - DO NOT duplicate:
- PostToolUse (Write|Edit): {FORMATTER} auto-formats your code
- PostToolUse (Write|Edit): {LINTER} auto-fixes lint issues
- PreToolUse (Write|Edit): secrets-check blocks credentials

If you see formatting issues after an edit, the hook may have failed.
Report to the user rather than trying to fix manually.

## When Done
Return a summary with:
- What you did
- Files changed
- Any issues
```

---

## Step 8: Final Report

```
Swarm Complete

Task: {FEATURE}
Stack: {STACK}
Template: {TEMPLATE}

Hooks Installed:
- PostToolUse: {FORMATTER} (Write|Edit)
- PostToolUse: {LINTER} (Write|Edit)
- PreToolUse: secrets-check (Write|Edit)
- PreToolUse: block-dangerous (Bash)

Results:
#1 [completed] Build      ✓
#2 [completed] Lint       ✓
#3 [completed] Validate   ✓ (N tests passed)
#4 [completed] Document   ✓

Hooks remain in .claude/settings.json
Run /cleanup-swarm to remove
```

---

## Hook Reference

### Available Hooks by Stack

| Stack | Formatter | Linter | Security |
|-------|-----------|--------|----------|
| python | ruff-format.sh | ruff-check.sh | secrets-check.sh |
| angular | prettier.sh | eslint.sh | secrets-check.sh |
| kotlin | ktlint.sh | (detekt manual) | secrets-check.sh |
| sql | sqlfluff-format.sh | yamllint.sh | secrets-check.sh |
| terraform | terraform-fmt.sh | tflint.sh | secrets-check.sh |
| airflow | ruff-format.sh | ruff-check.sh | secrets-check.sh |
| yaml | prettier.sh | yamllint.sh | secrets-check.sh |

### Hook Locations

```
~/.claude/swarm-generator/hooks/
├── formatters/
│   ├── ruff-format.sh      # Python
│   ├── prettier.sh         # Angular, YAML
│   ├── ktlint.sh           # Kotlin
│   ├── sqlfluff-format.sh  # SQL
│   └── terraform-fmt.sh    # Terraform
├── validators/
│   ├── ruff-check.sh       # Python
│   ├── eslint.sh           # Angular
│   ├── tflint.sh           # Terraform
│   └── yamllint.sh         # YAML
├── security/
│   ├── secrets-check.sh    # All stacks
│   └── block-dangerous.sh  # All stacks
└── common/
    └── notify-macos.sh     # Optional
```

---

## Error Handling

- **Hook missing:** Create it using template above, then continue
- **Hook fails:** Report to user, continue without that hook
- **Agent fails:** Mark task failed, ask user how to proceed
- **Tests fail:** Report failures, optionally create refactor task
