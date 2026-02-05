---
name: deploy-swarm
description: "Generate and deploy multi-agent swarms with hooks for any project. Use when setting up development pipelines, code review workflows, or refactoring automation. Invoke with /deploy-swarm"
---

# Swarm Generator & Deployer

Generate complete multi-agent swarm configurations with appropriate hooks for any project.

## Quick Start

```
/deploy-swarm                    # Interactive mode - detects stack, prompts for template
/deploy-swarm typescript         # Explicit stack
/deploy-swarm python dev-pipeline "Add user auth"   # Full specification
```

## Workflow

### Phase 1: Stack Detection & Validation

1. **Auto-detect** the tech stack by checking for:
   - `package.json`, `tsconfig.json` → TypeScript
   - `pyproject.toml`, `requirements.txt` → Python
   - `Cargo.toml` → Rust
   - `go.mod` → Go

2. **Validate** with user:
   ```
   Detected: TypeScript (package.json found)
   Tools: prettier, eslint, jest

   Is this correct? [Y/n/override]
   ```

3. **If override requested**, present available stacks:
   ```
   Available stacks:
   1. typescript - prettier, eslint, jest
   2. python - ruff, pytest
   3. rust - rustfmt, clippy, cargo test
   4. go - gofmt, golangci-lint, go test
   5. custom - specify your own tools
   ```

### Phase 2: Template Selection

1. **Present templates**:
   ```
   Available templates:
   1. dev-pipeline - Build → Lint → Test → Document (4 teammates)
   2. code-review - Review → Security → Approve (3 teammates)
   3. refactor - Analyze → Plan → Implement → Validate (4 teammates)
   4. custom - define your own workflow
   ```

2. **If custom**, prompt for:
   - Teammate names and roles
   - Task pipeline and dependencies
   - Option to save as new template

### Phase 3: Hook Generation

For each teammate in the template:

1. **Check required hooks** from `teammate.required_hooks`
2. **Map to stack-specific hooks** from `stack.hooks[teammate]`
3. **Verify hooks exist** in `~/.claude/swarm-generator/hooks/`
4. **Generate missing hooks** if needed

#### Hook Mapping

| Teammate | Required Hook | TypeScript | Python | Rust | Go |
|----------|---------------|------------|--------|------|-----|
| builder | format-on-save | prettier.sh | ruff-format.sh | rustfmt.sh | gofmt.sh |
| linter | formatter | prettier.sh | ruff-format.sh | rustfmt.sh | gofmt.sh |
| linter | linter | eslint.sh | ruff-check.sh | clippy.sh | golangci.sh |
| validator | test-runner | jest | pytest | cargo test | go test |
| security | secrets-check | secrets-check.sh | secrets-check.sh | secrets-check.sh | secrets-check.sh |

### Phase 4: Generate Configuration

Generate `settings.json` hooks section:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": ["~/.claude/swarm-generator/hooks/formatters/{{formatter}}.sh"]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": ["~/.claude/swarm-generator/hooks/security/secrets-check.sh"]
      },
      {
        "matcher": "Bash",
        "hooks": ["~/.claude/swarm-generator/hooks/security/block-dangerous.sh"]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": ["~/.claude/swarm-generator/hooks/common/notify-macos.sh"]
      }
    ]
  }
}
```

### Phase 5: Generate Teammate Prompts

For each teammate, generate prompt with:

1. **Role description** from template
2. **Hook awareness** - what hooks run automatically
3. **Stack-specific commands** (e.g., `npm test` vs `pytest`)
4. **Communication patterns**

Template variable substitution:
- `{{feature}}` - user's feature description
- `{{test_command}}` - stack's test runner command
- `{{format_command}}` - stack's formatter command

### Phase 6: Deploy

1. **Create team**:
   ```javascript
   Teammate({ operation: "spawnTeam", team_name: "{{team_name}}", description: "{{description}}" })
   ```

2. **Create tasks** with dependencies:
   ```javascript
   TaskCreate({ subject: "Build: {{feature}}", ... })
   TaskCreate({ subject: "Lint: ...", ... })
   TaskUpdate({ taskId: "2", addBlockedBy: ["1"] })
   // etc.
   ```

3. **Spawn teammates** (all with `run_in_background: true`):
   ```javascript
   Task({ team_name: "...", name: "builder", subagent_type: "general-purpose", prompt: "...", run_in_background: true })
   // etc.
   ```

4. **Report deployment**:
   ```
   Swarm deployed: dev-pipeline
   Stack: typescript
   Teammates: builder, linter, validator, documenter

   Hooks installed:
   - PostToolUse: prettier.sh (Write|Edit)
   - PreToolUse: secrets-check.sh (Write|Edit)
   - PreToolUse: block-dangerous.sh (Bash)

   Monitor: TaskList()
   Messages: cat ~/.claude/teams/{{team}}/inboxes/team-lead.json
   Cleanup: /cleanup-swarm {{team}}
   ```

## Saving Custom Templates

When user creates a custom configuration:

```
Save this configuration as a template? [y/N]
Template name: my-custom-pipeline
```

Save to: `~/.claude/swarm-generator/templates/custom/my-custom-pipeline.json`

## File Locations

```
~/.claude/swarm-generator/
├── stacks/
│   ├── typescript.json      # Pre-defined stacks
│   ├── python.json
│   ├── rust.json
│   ├── go.json
│   └── custom/              # User-created stacks
│       └── my-stack.json
├── templates/
│   ├── dev-pipeline.json    # Pre-defined templates
│   ├── code-review.json
│   ├── refactor.json
│   └── custom/              # User-saved templates
│       └── my-template.json
├── hooks/
│   ├── formatters/
│   │   ├── prettier.sh
│   │   ├── ruff-format.sh
│   │   ├── rustfmt.sh
│   │   └── gofmt.sh
│   ├── validators/
│   │   ├── eslint.sh
│   │   └── ruff-check.sh
│   ├── security/
│   │   ├── secrets-check.sh
│   │   └── block-dangerous.sh
│   └── common/
│       ├── audit-log.sh
│       └── notify-macos.sh
└── SKILL.md
```

## Hook Installation

Hooks are installed to the project's `.claude/settings.json`:

```javascript
// Read existing settings
const existingSettings = readFileSync('.claude/settings.json') || {}

// Merge hooks (don't overwrite existing)
const mergedHooks = {
  ...existingSettings.hooks,
  PostToolUse: [
    ...(existingSettings.hooks?.PostToolUse || []),
    ...newHooks.PostToolUse
  ],
  // etc.
}

// Write back
writeFileSync('.claude/settings.json', { ...existingSettings, hooks: mergedHooks })
```

## Cleanup

When user says "cleanup" or "/cleanup-swarm":

```javascript
// Request shutdown from all teammates
for (const teammate of teammates) {
  Teammate({ operation: "requestShutdown", target_agent_id: teammate })
}

// Wait for approvals
// ...

// Cleanup
Teammate({ operation: "cleanup" })

// Optionally remove hooks
// (ask user: "Remove installed hooks? [y/N]")
```

## Examples

### Example 1: Quick TypeScript Pipeline

```
User: /deploy-swarm
Claude: Detected TypeScript project. Using dev-pipeline template.
        Feature to build?
User: Add JWT authentication
Claude: [Deploys swarm with builder, linter, validator, documenter]
        [Installs prettier.sh, eslint.sh, secrets-check.sh hooks]
```

### Example 2: Python Code Review

```
User: /deploy-swarm python code-review
Claude: [Deploys code-review swarm for Python]
        [Installs ruff hooks, secrets-check]
```

### Example 3: Custom Template

```
User: /deploy-swarm --custom
Claude: Define your teammates:
User: builder, tester, security
Claude: Define task pipeline:
User: Build → Test → Security (parallel with Test)
Claude: Save as template?
User: yes, call it "secure-dev"
Claude: [Saves to templates/custom/secure-dev.json]
        [Deploys swarm]
```

## Integration with Project Settings

The generated hooks integrate with existing project `.claude/settings.json`. The skill:

1. **Reads** existing settings
2. **Merges** new hooks (avoiding duplicates)
3. **Preserves** user customizations
4. **Reports** what was added

## Teammate Hook Awareness

Each teammate prompt includes hook awareness section:

```
## Hook Awareness
The following hooks run automatically:
- PostToolUse (Write|Edit): Auto-formats code with prettier
- PreToolUse (Write|Edit): Blocks potential secrets

DO NOT manually run formatters - hooks handle this.
If you see formatting issues after edit, the hook may have failed - report to team-lead.
```

This ensures teammates don't duplicate hook functionality and understand the automated quality gates.
