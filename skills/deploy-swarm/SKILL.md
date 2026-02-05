---
name: deploy-swarm
description: "Generate and deploy multi-agent swarms with hooks. Auto-detects tech stack, selects templates, installs hooks, spawns teammates. Use for dev pipelines, code review, refactoring workflows."
---

# Deploy Swarm (v2.3)

Generate and deploy a complete multi-agent swarm with **enforced** hooks.

**v2.3 Changes:**
- **ENFORCED hook verification** — Swarm will NOT start unless hooks are configured in settings.json
- Verification checks both file existence AND settings.json configuration
- Clear PASS/FAIL gate before spawning any subagents

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

## Step 3: Hook Enforcement (CRITICAL - BLOCKING GATE)

**This step is MANDATORY. Do NOT proceed to Step 4 unless ALL checks pass.**

### 3a. Define Required Hooks for Stack

Map the stack to required hook scripts:

| Stack | Formatter | Linter | Security |
|-------|-----------|--------|----------|
| python | ruff-format.sh | ruff-check.sh | secrets-check.sh |
| angular | prettier.sh | eslint.sh | secrets-check.sh |
| kotlin | ktlint.sh | — | secrets-check.sh |
| terraform | terraform-fmt.sh | tflint.sh | secrets-check.sh |
| sql | sqlfluff-format.sh | yamllint.sh | secrets-check.sh |
| airflow | ruff-format.sh | ruff-check.sh | secrets-check.sh |
| yaml | prettier.sh | yamllint.sh | secrets-check.sh |

### 3b. Verify Hook FILES Exist

```bash
HOOKS_DIR="$HOME/.claude/swarm-generator/hooks"

# Check each required hook file
echo "=== Hook File Verification ==="
[ -x "$HOOKS_DIR/formatters/{FORMATTER}" ] && echo "✓ {FORMATTER} exists" || echo "✗ {FORMATTER} MISSING"
[ -x "$HOOKS_DIR/validators/{LINTER}" ] && echo "✓ {LINTER} exists" || echo "✗ {LINTER} MISSING"
[ -x "$HOOKS_DIR/security/secrets-check.sh" ] && echo "✓ secrets-check.sh exists" || echo "✗ secrets-check.sh MISSING"
[ -x "$HOOKS_DIR/security/block-dangerous.sh" ] && echo "✓ block-dangerous.sh exists" || echo "✗ block-dangerous.sh MISSING"
```

### 3c. Verify Hooks are CONFIGURED in settings.json (CRITICAL)

**This is the enforcement step. Check that hooks are actually wired up to fire.**

```bash
echo "=== Hook Configuration Verification ==="
SETTINGS="$HOME/.claude/settings.json"

# Check if settings.json exists
if [ ! -f "$SETTINGS" ]; then
  echo "✗ FAIL: ~/.claude/settings.json does not exist"
  echo "  Run: ./install.sh to configure hooks"
  exit 1
fi

# Check PostToolUse hooks are configured
FORMATTER_CONFIGURED=$(jq -r '.hooks.PostToolUse[]?.hooks[]? | select(contains("{FORMATTER}"))' "$SETTINGS" 2>/dev/null)
if [ -n "$FORMATTER_CONFIGURED" ]; then
  echo "✓ {FORMATTER} configured in PostToolUse"
else
  echo "✗ FAIL: {FORMATTER} NOT configured in settings.json"
fi

# Check PreToolUse security hooks
SECRETS_CONFIGURED=$(jq -r '.hooks.PreToolUse[]?.hooks[]? | select(contains("secrets-check"))' "$SETTINGS" 2>/dev/null)
if [ -n "$SECRETS_CONFIGURED" ]; then
  echo "✓ secrets-check.sh configured in PreToolUse"
else
  echo "✗ FAIL: secrets-check.sh NOT configured in settings.json"
fi

DANGEROUS_CONFIGURED=$(jq -r '.hooks.PreToolUse[]?.hooks[]? | select(contains("block-dangerous"))' "$SETTINGS" 2>/dev/null)
if [ -n "$DANGEROUS_CONFIGURED" ]; then
  echo "✓ block-dangerous.sh configured in PreToolUse"
else
  echo "✗ FAIL: block-dangerous.sh NOT configured in settings.json"
fi
```

### 3d. Enforcement Decision

**If ANY check failed:**

```
┌─────────────────────────────────────────────────────────────────┐
│  HOOK ENFORCEMENT FAILED                                         │
│                                                                  │
│  Missing hooks in settings.json:                                 │
│  - {list failed hooks}                                          │
│                                                                  │
│  Swarm CANNOT proceed without enforced hooks.                   │
│                                                                  │
│  To fix:                                                         │
│  1. Run install.sh from claude-swarm-generator repo             │
│  2. Or manually add hooks to ~/.claude/settings.json            │
│  3. Restart Claude Code                                          │
│  4. Re-run /deploy-swarm                                        │
└─────────────────────────────────────────────────────────────────┘
```

**STOP HERE. Do not proceed to Step 4.**

**If ALL checks passed:**

```
┌─────────────────────────────────────────────────────────────────┐
│  HOOK ENFORCEMENT PASSED ✓                                       │
│                                                                  │
│  All required hooks verified:                                    │
│  ✓ File exists    ✓ Configured in settings.json                 │
│                                                                  │
│  - PostToolUse: {FORMATTER} (Write|Edit|MultiEdit)              │
│  - PostToolUse: {LINTER} (Write|Edit|MultiEdit)                 │
│  - PreToolUse: secrets-check.sh (Write|Edit)                    │
│  - PreToolUse: block-dangerous.sh (Bash)                        │
│                                                                  │
│  Proceeding to spawn teammates...                                │
└─────────────────────────────────────────────────────────────────┘
```

**Proceed to Step 4.**

---

## Step 4: Create Tasks

Create tasks from template with dependencies:

```javascript
TaskCreate({ subject: "Build: <feature>", description: "...", activeForm: "Building..." })
TaskCreate({ subject: "Lint: Format and verify", ... })
TaskUpdate({ taskId: "2", addBlockedBy: ["1"] })
// etc.
```

---

## Step 5: Sequential Agent Spawning

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

## Step 6: Agent Prompts with Hook Awareness

**Every agent prompt MUST include hook awareness section:**

```
You are {ROLE} in a {TEMPLATE} swarm.

## Your Task
{TASK_DESCRIPTION}

## Instructions
{ROLE_SPECIFIC_INSTRUCTIONS}

## Hook Awareness (ENFORCED)
These hooks are VERIFIED to be configured and WILL run automatically:
- PostToolUse (Write|Edit): {FORMATTER} auto-formats your code
- PostToolUse (Write|Edit): {LINTER} auto-checks for issues
- PreToolUse (Write|Edit): secrets-check.sh blocks credentials
- PreToolUse (Bash): block-dangerous.sh blocks destructive commands

DO NOT manually run formatters or linters - they run automatically.
If you see unexpected formatting, the hook is working.

## When Done
Return a summary with:
- What you did
- Files changed
- Any issues
```

---

## Step 7: Final Report

```
Swarm Complete

Task: {FEATURE}
Stack: {STACK}
Template: {TEMPLATE}

Hooks Enforced (verified before execution):
✓ PostToolUse: {FORMATTER} (Write|Edit)
✓ PostToolUse: {LINTER} (Write|Edit)
✓ PreToolUse: secrets-check (Write|Edit)
✓ PreToolUse: block-dangerous (Bash)

Results:
#1 [completed] Build      ✓
#2 [completed] Lint       ✓
#3 [completed] Validate   ✓ (N tests passed)
#4 [completed] Document   ✓

Hooks remain in ~/.claude/settings.json
Run /cleanup-swarm to remove tasks
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

- **Hook file missing:** STOP. User must install hooks first.
- **Hook not in settings.json:** STOP. User must run install.sh or manually configure.
- **Agent fails:** Mark task failed, ask user how to proceed.
- **Tests fail:** Report failures, optionally loop back to builder for refactor.
