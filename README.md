# Claude Swarm Generator

Multi-agent swarm orchestration for Claude Code with **enforced** deterministic hooks and coordinated teammates.

## What Is This?

This tool generates **swarms**—coordinated teams of Claude agents that work together on complex tasks. Unlike ad-hoc prompting, swarms provide:

- **Structured workflows** with task dependencies
- **Specialized teammates** with defined roles and tool restrictions
- **Enforced hooks** that are verified before any subagent spawns
- **Feedback loops** where validators can trigger builder refactors

**v2.3:** Hook enforcement is now a blocking gate. Swarms will NOT start unless all required hooks are verified to be configured in `~/.claude/settings.json`.

## Key Concepts

### Teammates vs Subagents

| Aspect | Subagent | Teammate |
|--------|----------|----------|
| **Lifecycle** | Short-lived, single task | Persistent, multiple tasks |
| **Context** | Fresh start each call | Maintains session context |
| **Communication** | Returns result directly | Can coordinate with other teammates |
| **Task management** | No task awareness | Works from shared task list |
| **Use case** | Quick lookups, searches | Pipeline stages, collaborative work |

**Subagent example:** "Search for all authentication files" → Returns file list → Done

**Teammate example:** Builder writes code → Validator runs tests → If tests fail, Builder refactors → Validator re-tests → Documenter summarizes

### Deterministic Hooks (Enforced)

Hooks are shell scripts that run **automatically** at specific lifecycle events—Claude doesn't choose whether to run them, they just happen.

```
┌─────────────────────────────────────────────────────────────────┐
│  BEFORE SWARM STARTS                                             │
│         │                                                        │
│         ▼                                                        │
│  Verify hooks exist as files                                     │
│         │                                                        │
│         ▼                                                        │
│  Verify hooks are configured in settings.json  ◄── BLOCKING GATE │
│         │                                                        │
│         ▼                                                        │
│  If ANY check fails → STOP (do not spawn subagents)              │
│  If ALL checks pass → Proceed to spawn teammates                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  DURING EXECUTION (after enforcement passes)                     │
│         │                                                        │
│         ▼                                                        │
│  Subagent edits a Python file                                    │
│         │                                                        │
│         ▼                                                        │
│  PostToolUse hook fires automatically                            │
│         │                                                        │
│         ▼                                                        │
│  ruff-format.sh runs (guaranteed - we verified it's configured)  │
└─────────────────────────────────────────────────────────────────┘
```

**Why enforced?**
- Claude might forget to run a formatter → Hooks run automatically
- Skills are "advisory"—Claude may skip them → Hooks always execute
- Hooks might not be configured → **Enforcement verifies before starting**

**Hook types:**

| Event | When | Purpose | Example |
|-------|------|---------|---------|
| `PreToolUse` | Before tool runs | Block dangerous operations | `secrets-check.sh` blocks credentials |
| `PostToolUse` | After tool completes | Auto-format, lint | `ruff-format.sh` formats Python |
| `Notification` | Claude wants attention | Desktop alerts | `notify-macos.sh` |
| `Stop` | Claude finishes | Run tests | `npm test` |

## Templates & Teammates

### dev-pipeline
**Workflow:** Build → Lint → Test → Document

| Teammate | Role | Allowed Tools |
|----------|------|---------------|
| **builder** | Writes code, implements features | Read, Glob, Grep, Edit, Write |
| **linter** | Formats code, fixes lint errors | Read, Glob, Grep, Edit, Bash |
| **validator** | Runs tests, reports failures | Read, Glob, Grep, Bash, Edit |
| **documenter** | Summarizes project status | Read, Glob, Grep, Edit |

### code-review
**Workflow:** Review → Security → Approve → Document

| Teammate | Role | Allowed Tools |
|----------|------|---------------|
| **reviewer** | Reviews code quality and patterns | Read, Glob, Grep, Edit |
| **security** | Scans for vulnerabilities, secrets | Read, Glob, Grep, Edit |
| **approver** | Makes final approval decision | Read, Glob, Grep, Edit |
| **documenter** | Compiles review summary | Read, Glob, Grep, Edit |

### refactor
**Workflow:** Analyze → Plan → Implement → Validate → Document

| Teammate | Role | Allowed Tools |
|----------|------|---------------|
| **analyzer** | Identifies refactoring opportunities | Read, Glob, Grep, Edit |
| **planner** | Creates step-by-step refactoring plan | Read, Glob, Grep, Edit |
| **builder** | Implements refactoring changes | Read, Glob, Grep, Edit, Write |
| **validator** | Verifies no regressions | Read, Glob, Grep, Bash, Edit |
| **documenter** | Summarizes all changes | Read, Glob, Grep, Edit |

## Workflow: The Refactor Loop

When validator finds issues, the workflow loops back to builder:

```
                    ┌──────────────────────────────────────┐
                    │                                      │
                    ▼                                      │
┌─────────┐    ┌─────────┐    ┌───────────┐    ┌──────────┴──┐
│ Analyze │───▶│  Plan   │───▶│  Builder  │───▶│  Validator  │
└─────────┘    └─────────┘    └───────────┘    └─────────────┘
                                    ▲                │
                                    │                │
                                    │    FAIL?       │
                                    └────────────────┘
                                    (refactor loop)

                                         │ PASS
                                         ▼
                                  ┌────────────┐
                                  │ Documenter │
                                  └────────────┘
```

This is managed by the **leader** (you), who:
1. Spawns builder, waits for completion
2. Spawns validator, checks results
3. If tests fail: spawns builder again with failure context
4. If tests pass: proceeds to documenter

## Stacks

Each stack defines language-specific tooling:

| Stack | Formatter | Linter | Test Command |
|-------|-----------|--------|--------------|
| **python** | ruff-format.sh | ruff-check.sh | `pytest` |
| **angular** | prettier.sh | eslint.sh | `ng test` |
| **kotlin** | ktlint.sh | — | `./gradlew test` |
| **terraform** | terraform-fmt.sh | tflint.sh | `terraform validate` |
| **sql** | sqlfluff-format.sh | yamllint.sh | — |
| **airflow** | ruff-format.sh | ruff-check.sh | `pytest` |
| **yaml** | prettier.sh | yamllint.sh | `yamllint .` |

## Installation

```bash
git clone https://github.com/KCPI150/claude-swarm-generator
cd claude-swarm-generator
chmod +x install.sh
./install.sh
```

**Restart Claude Code** for hooks to take effect.

This installs:
- Swarm generator to `~/.claude/swarm-generator/`
- Skills to `~/.claude/skills/`
- Hooks to `~/.claude/swarm-generator/hooks/`

## Usage

```bash
/deploy-swarm                    # Interactive - detects stack
/deploy-swarm python             # Specify stack
/deploy-swarm yaml refactor      # Specify stack and template
/cleanup-swarm                   # Clean up tasks after swarm
```

### Example Session

```
$ /deploy-swarm python dev-pipeline "Add JWT authentication"

Detected: python (found *.py files)
Template: dev-pipeline
Feature: Add JWT authentication

Hook Verification:
✓ ruff-format.sh exists
✓ ruff-check.sh exists
✓ secrets-check.sh exists
✓ block-dangerous.sh exists

Creating tasks...
#1 Build: Add JWT authentication
#2 Lint: Format and verify (blocked by #1)
#3 Validate: Run tests (blocked by #2)
#4 Document: Summarize status (blocked by #3)

[1/4] Building...
  → builder completed: created auth.py, jwt_utils.py
[2/4] Linting...
  → linter completed: 0 issues
[3/4] Validating...
  → validator completed: 12 tests passed
[4/4] Documenting...
  → documenter completed: updated SWARM-SUMMARY.md

Swarm Complete ✓
Results saved to: docs/SWARM-SUMMARY.md
```

## Hooks

### Included Hooks

**Formatters** (PostToolUse on Write|Edit):
- `ruff-format.sh` — Python (falls back to black)
- `prettier.sh` — JS/TS/YAML/JSON
- `ktlint.sh` — Kotlin
- `sqlfluff-format.sh` — SQL
- `terraform-fmt.sh` — Terraform

**Validators** (PostToolUse on Write|Edit):
- `ruff-check.sh` — Python linting
- `eslint.sh` — JavaScript/TypeScript linting
- `tflint.sh` — Terraform linting
- `yamllint.sh` — YAML linting

**Security** (PreToolUse):
- `secrets-check.sh` — Blocks AWS keys, API tokens, passwords
- `block-dangerous.sh` — Blocks `rm -rf /`, `DROP TABLE`, etc.

**Common**:
- `notify-macos.sh` — Desktop notifications

### Hook Configuration

Hooks are installed to `.claude/settings.json` in your project:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": {"tools": ["Write", "Edit", "MultiEdit"]},
        "hooks": [{"type": "command", "command": "/path/to/ruff-format.sh"}]
      }
    ],
    "PreToolUse": [
      {
        "matcher": {"tools": ["Write", "Edit"]},
        "hooks": [{"type": "command", "command": "/path/to/secrets-check.sh"}]
      },
      {
        "matcher": {"tools": ["Bash"]},
        "hooks": [{"type": "command", "command": "/path/to/block-dangerous.sh"}]
      }
    ]
  }
}
```

### How Hooks Work

**PostToolUse** receives environment variables:
- `$CLAUDE_FILE_PATHS` — Space-separated list of affected files

**PreToolUse** receives JSON via stdin and must return a decision:
```json
{"decision": "allow"}
{"decision": "block", "reason": "Potential secret detected"}
{"decision": "skip"}
```

## Output

Each swarm creates documentation in your project:

```
your-project/
└── docs/
    └── SWARM-SUMMARY.md    # Agent summaries and final status
```

## Tool Restrictions

Each teammate has explicit tool restrictions to prevent scope creep:

| Teammate | Why These Tools |
|----------|-----------------|
| builder | Needs Write to create files, no Bash to avoid installing dependencies |
| linter | Needs Bash to run linters, no Write to avoid creating new files |
| validator | Needs Bash for tests, no Write to avoid fixing (just reporting) |
| documenter | Read-only analysis, Edit only for summary file |
| security | Read-only scanning, no execution capabilities |

## Uninstall

```bash
./uninstall.sh
```

Removes swarm-generator, skills, and hooks from `~/.claude/`.

## Requirements

- Claude Code CLI
- `jq` (for hook configuration)
- Stack-specific tools:
  - Python: `ruff` or `black`, `pytest`
  - Angular: `prettier`, `eslint`, `ng`
  - Terraform: `terraform`, `tflint`
  - etc.

## Custom Stacks & Templates

Add custom configurations to:
- `~/.claude/swarm-generator/stacks/custom/`
- `~/.claude/swarm-generator/templates/custom/`

See existing JSON files for the schema.

## License

MIT
