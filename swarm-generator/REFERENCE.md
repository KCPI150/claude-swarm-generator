# Claude Code: Hooks, Skills, and Swarm Orchestration

A practical guide to extending Claude Code's capabilities through hooks, skills, and multi-agent coordination.

---

## Table of Contents

1. [Overview: Three Extension Mechanisms](#overview-three-extension-mechanisms)
2. [Hooks](#hooks)
   - [What Are Hooks?](#what-are-hooks)
   - [The Four Hook Events](#the-four-hook-events)
   - [Where Hooks Live](#where-hooks-live)
   - [Hook Configuration](#hook-configuration)
   - [Hook Input/Output](#hook-inputoutput)
   - [Practical Hook Examples](#practical-hook-examples)
3. [Skills](#skills)
   - [What Are Skills?](#what-are-skills)
   - [Where Skills Live](#where-skills-live)
   - [Skill Structure](#skill-structure)
4. [Hooks vs Skills: When to Use Which](#hooks-vs-skills-when-to-use-which)
5. [Swarm Orchestration](#swarm-orchestration)
   - [Core Primitives](#core-primitives)
   - [Two Ways to Spawn Agents](#two-ways-to-spawn-agents)
   - [TeammateTool Operations](#teammatetool-operations)
   - [Task System](#task-system)
6. [Putting It All Together](#putting-it-all-together)
7. [Included Examples](#included-examples)
8. [Quick Reference](#quick-reference)

---

## Overview: Three Extension Mechanisms

Claude Code provides three distinct ways to extend its behavior:

| Mechanism | Execution Model | Best For |
|-----------|-----------------|----------|
| **Hooks** | Automatic at lifecycle events | Enforcement, logging, formatting |
| **Skills** | Claude chooses to follow | Guidelines, patterns, best practices |
| **Swarm/TeammateTool** | Explicit orchestration | Parallel work, pipelines, complex workflows |

Think of it this way:
- **Hooks** = "This WILL happen" (deterministic)
- **Skills** = "Claude SHOULD do this" (advisory)
- **Swarm** = "Coordinate multiple Claudes" (orchestration)

---

## Hooks

### What Are Hooks?

Hooks are lifecycle event handlers that run custom shell commands at specific points during Claude Code's execution. They fire automatically — Claude doesn't choose whether to run them.

```
User request → Claude uses tool → Hook fires → Command executes
                                      ↑
                              (automatic, guaranteed)
```

### The Four Hook Events

| Event | When It Fires | Use Cases |
|-------|---------------|-----------|
| `PreToolUse` | Before a tool runs | Block commands, validate paths, require confirmation |
| `PostToolUse` | After a tool completes | Auto-format code, log actions, capture outputs |
| `Notification` | When Claude wants attention | Desktop alerts, sounds, Slack messages |
| `Stop` | When Claude finishes responding | Run tests, lint checks, commit reminders |

### Where Hooks Live

Hooks are defined in `settings.json`:

**Global (all projects):**
```
~/.claude/settings.json
```

**Project-specific:**
```
your-project/.claude/settings.json
```

Project settings merge with global — you can have baseline hooks everywhere plus project-specific ones.

### Hook Configuration

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": ["ruff format $CLAUDE_FILE_PATHS"]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": ["./.claude/hooks/validate-command.sh"]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": ["osascript -e 'display notification \"Claude needs you\"'"]
      }
    ]
  }
}
```

**Key fields:**
- `matcher`: Regex against tool names (empty string = match all)
- `hooks`: Array of commands to run sequentially

### Hook Input/Output

**Input (via stdin):** JSON with session info, tool name, and tool input

```json
{
  "session_id": "abc123",
  "tool_name": "Bash",
  "tool_input": {
    "command": "npm install"
  }
}
```

**Output (PreToolUse only):** Return JSON to control behavior

```json
{"decision": "allow"}                              // proceed normally
{"decision": "block", "reason": "Not permitted"}   // stop with message
{"decision": "skip"}                               // skip silently
```

### Practical Hook Examples

#### 1. Auto-format after every edit

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          "npx prettier --write $CLAUDE_FILE_PATHS",
          "npx eslint --fix $CLAUDE_FILE_PATHS"
        ]
      }
    ]
  }
}
```

#### 2. Block dangerous commands

```bash
#!/bin/bash
# .claude/hooks/block-dangerous.sh
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if echo "$COMMAND" | grep -qE 'rm -rf /|DROP TABLE|--force'; then
  echo '{"decision": "block", "reason": "Dangerous command pattern detected"}'
  exit 0
fi

echo '{"decision": "allow"}'
```

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": ["./.claude/hooks/block-dangerous.sh"]
      }
    ]
  }
}
```

#### 3. Desktop notifications

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": ["osascript -e 'display notification \"Claude needs you\" with title \"Claude Code\"'"]
      }
    ]
  }
}
```

#### 4. Auto-run tests after changes

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": ["npm test --silent 2>&1 | tail -5"]
      }
    ]
  }
}
```

#### 5. Audit logging

```bash
#!/bin/bash
# .claude/hooks/audit-log.sh
INPUT=$(cat)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TOOL=$(echo "$INPUT" | jq -r '.tool_name')
echo "$TIMESTAMP | $TOOL | $INPUT" >> ~/.claude/audit.log
```

---

## Skills

### What Are Skills?

Skills are instruction files that teach Claude how to approach specific tasks. Unlike hooks, Claude *chooses* to follow skills based on context — they're advisory, not enforced.

```
User request → Claude reads SKILL.md → Claude decides how to proceed
                                            ↑
                                   (contextual, may adapt)
```

### Where Skills Live

```
your-project/.claude/skills/
├── dev-pipeline-swarm/
│   └── SKILL.md
├── code-review/
│   └── SKILL.md
└── deployment/
    └── SKILL.md
```

Or reference external skills:
```
~/.claude/skills/
└── my-global-skill/
    └── SKILL.md
```

### Skill Structure

```markdown
---
name: my-skill
description: "When to use this skill - triggers and contexts"
---

# Skill Title

## Overview
What this skill does and when to use it.

## Instructions
Step-by-step guidance for Claude.

## Examples
Concrete examples of usage.

## Rules
Constraints and requirements.
```

**See:** [`SKILL.md`](./SKILL.md) for a complete example.

---

## Hooks vs Skills: When to Use Which

| Aspect | Hooks | Skills |
|--------|-------|--------|
| **Execution** | Automatic, guaranteed | Claude chooses contextually |
| **Reliability** | Always runs | May forget or skip |
| **Flexibility** | Fixed behavior | Adapts to situation |
| **Configuration** | `settings.json` | `.md` files |
| **Use case** | Enforcement | Guidance |

### Use Hooks For:
- ✅ Code formatting (must always happen)
- ✅ Security gates (block certain commands)
- ✅ Audit logging (compliance requirement)
- ✅ Notifications (always want to know)
- ✅ Test runs (automated quality gate)

### Use Skills For:
- ✅ Coding patterns and conventions
- ✅ Architecture guidelines
- ✅ Documentation standards
- ✅ Workflow instructions
- ✅ Things with exceptions

### Combine Them

A skill can say "follow our coding standards" while a hook enforces the formatter. The skill handles nuance; the hook handles the non-negotiable.

```
SKILL.md: "Use descriptive variable names, prefer const over let..."
Hook: "Always run prettier after edits" (no exceptions)
```

### Do You Document Hooks in Skills?

Only if Claude's behavior should *account for* the hook:

```markdown
# SKILL.md

## Code Quality
A post-edit hook runs prettier automatically — don't run formatters manually.
```

This prevents Claude from duplicating effort. But you don't *instruct* hooks to run — they just do.

---

## Swarm Orchestration

Swarm orchestration lets you coordinate multiple Claude instances working together on complex tasks.

### Core Primitives

| Primitive | What It Is | Location |
|-----------|------------|----------|
| **Team** | Named group of agents (leader + teammates) | `~/.claude/teams/{name}/config.json` |
| **Teammate** | Agent in a team with inbox for messages | Listed in team config |
| **Task** | Work item with status, owner, dependencies | `~/.claude/tasks/{team}/N.json` |
| **Inbox** | JSON file for inter-agent messaging | `~/.claude/teams/{name}/inboxes/{agent}.json` |

### File Structure

```
~/.claude/teams/{team-name}/
├── config.json              # Team metadata and members
└── inboxes/
    ├── team-lead.json       # Leader's inbox (you)
    ├── worker-1.json        # Worker inboxes
    └── worker-2.json

~/.claude/tasks/{team-name}/
├── 1.json                   # Task #1
├── 2.json                   # Task #2
└── 3.json                   # Task #3
```

### Two Ways to Spawn Agents

#### 1. Task Tool (Simple Subagent)

Short-lived, returns result directly:

```javascript
Task({
  subagent_type: "Explore",
  description: "Find auth files",
  prompt: "Find all authentication-related files",
  model: "haiku"  // optional: haiku, sonnet, opus
})
```

**Characteristics:**
- Runs synchronously (or async with `run_in_background: true`)
- Returns result to you
- No team membership
- Best for: searches, analysis, quick tasks

#### 2. Task + team_name + name (Teammate)

Persistent, communicates via inbox:

```javascript
// First create a team
Teammate({ operation: "spawnTeam", team_name: "my-project" })

// Then spawn a teammate
Task({
  team_name: "my-project",        // Required: which team
  name: "security-reviewer",      // Required: teammate's name
  subagent_type: "general-purpose",
  prompt: "Review code for vulnerabilities. Send findings to team-lead.",
  run_in_background: true
})
```

**Characteristics:**
- Joins team, appears in config
- Communicates via inbox messages
- Can claim tasks from shared task list
- Persists until shutdown requested
- Best for: parallel work, pipelines, ongoing collaboration

### TeammateTool Operations

| Operation | Purpose | Who Can Use |
|-----------|---------|-------------|
| `spawnTeam` | Create a new team | Anyone |
| `write` | Message one teammate | Anyone |
| `broadcast` | Message ALL teammates | Anyone (expensive) |
| `requestShutdown` | Ask teammate to exit | Leader only |
| `approveShutdown` | Accept shutdown request | Teammate only |
| `cleanup` | Remove team resources | Leader only |

**Examples:**

```javascript
// Create team
Teammate({ operation: "spawnTeam", team_name: "feature-dev" })

// Message specific teammate
Teammate({
  operation: "write",
  target_agent_id: "builder",
  value: "Please prioritize the auth module"
})

// Shutdown sequence
Teammate({ operation: "requestShutdown", target_agent_id: "builder" })
// Wait for approval...
Teammate({ operation: "cleanup" })
```

### Task System

```javascript
// Create tasks
TaskCreate({
  subject: "Implement feature",
  description: "Build the user authentication system",
  activeForm: "Building..."  // shown in spinner
})

// Set up dependencies
TaskUpdate({ taskId: "2", addBlockedBy: ["1"] })  // #2 waits for #1

// Check progress
TaskList()
// Returns:
// #1 [completed] Implement feature (owner: builder)
// #2 [in_progress] Write tests (owner: tester)
// #3 [pending] Update docs [blocked by #2]

// Update status
TaskUpdate({ taskId: "1", status: "completed" })
```

**Task Dependencies:**

When a blocking task completes, blocked tasks auto-unblock:

```javascript
TaskCreate({ subject: "Step 1: Research" })       // #1
TaskCreate({ subject: "Step 2: Implement" })      // #2
TaskCreate({ subject: "Step 3: Test" })           // #3

TaskUpdate({ taskId: "2", addBlockedBy: ["1"] })  // #2 waits for #1
TaskUpdate({ taskId: "3", addBlockedBy: ["2"] })  // #3 waits for #2

// When #1 completes → #2 auto-unblocks
// When #2 completes → #3 auto-unblocks
```

---

## Putting It All Together

Here's how hooks, skills, and swarm orchestration complement each other:

```
┌─────────────────────────────────────────────────────────────────┐
│                     YOUR PROJECT                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────┐   ┌──────────────────┐   ┌──────────────┐ │
│  │      HOOKS       │   │      SKILLS      │   │    SWARM     │ │
│  │   (Enforcement)  │   │    (Guidance)    │   │(Orchestration)│ │
│  ├──────────────────┤   ├──────────────────┤   ├──────────────┤ │
│  │                  │   │                  │   │              │ │
│  │ • Auto-format    │   │ • Coding style   │   │ • Builder    │ │
│  │ • Block danger   │   │ • Architecture   │   │ • Linter     │ │
│  │ • Audit logs     │   │ • Workflow steps │   │ • Validator  │ │
│  │ • Notifications  │   │ • Best practices │   │ • Documenter │ │
│  │                  │   │                  │   │              │ │
│  └────────┬─────────┘   └────────┬─────────┘   └──────┬───────┘ │
│           │                      │                     │         │
│           └──────────────────────┼─────────────────────┘         │
│                                  │                               │
│                                  ▼                               │
│                    ┌─────────────────────────┐                   │
│                    │      CLAUDE CODE        │                   │
│                    │   (Executes everything) │                   │
│                    └─────────────────────────┘                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Example workflow:**

1. You invoke the dev-pipeline skill: "Add JWT authentication"
2. **Swarm** spawns builder, linter, validator, documenter
3. **Builder** writes code
4. **Hook** auto-formats every file edit (PostToolUse)
5. **Linter teammate** runs additional project-specific linting
6. **Validator** runs tests
7. **Hook** sends notification when tests complete
8. **Documenter** updates README following **skill** guidelines
9. You cleanup the team

---

## Included Examples

This repository includes two practical examples:

### 1. SKILL.md — Dev Pipeline Swarm

A complete multi-agent development pipeline with:
- **Builder**: Writes code, handles refactors
- **Linter**: Formats with project tools
- **Validator**: Runs tests, triggers refactor loop
- **Documenter**: Updates docs

**Usage:**
```
/project:dev-pipeline "Add user authentication with JWT tokens"
```

### 2. dev-pipeline.md — Slash Command

A companion command that invokes the skill with minimal typing.

**Installation:**
```
your-project/
└── .claude/
    ├── skills/
    │   └── dev-pipeline-swarm/
    │       └── SKILL.md
    └── commands/
        └── dev-pipeline.md
```

---

## Quick Reference

### Hook Configuration
```json
// .claude/settings.json
{
  "hooks": {
    "PostToolUse": [{ "matcher": "Write|Edit", "hooks": ["prettier --write $CLAUDE_FILE_PATHS"] }],
    "PreToolUse": [{ "matcher": "Bash", "hooks": ["./validate.sh"] }],
    "Notification": [{ "matcher": "", "hooks": ["notify-send 'Claude'"] }],
    "Stop": [{ "matcher": "", "hooks": ["npm test"] }]
  }
}
```

### Skill Structure
```markdown
---
name: my-skill
description: "Trigger conditions"
---
# Title
Instructions for Claude...
```

### Swarm Quick Start
```javascript
// 1. Create team
Teammate({ operation: "spawnTeam", team_name: "my-team" })

// 2. Create tasks
TaskCreate({ subject: "Step 1", description: "..." })
TaskCreate({ subject: "Step 2", description: "..." })
TaskUpdate({ taskId: "2", addBlockedBy: ["1"] })

// 3. Spawn teammates
Task({ team_name: "my-team", name: "worker", subagent_type: "general-purpose", prompt: "...", run_in_background: true })

// 4. Monitor
TaskList()
cat ~/.claude/teams/my-team/inboxes/team-lead.json

// 5. Cleanup
Teammate({ operation: "requestShutdown", target_agent_id: "worker" })
Teammate({ operation: "cleanup" })
```

### Decision Tree

```
Need to extend Claude Code?
│
├─ Must ALWAYS happen? → Use HOOK
│   Examples: formatting, logging, blocking
│
├─ Claude should CONSIDER? → Use SKILL
│   Examples: patterns, guidelines, workflows
│
└─ Need MULTIPLE agents? → Use SWARM
    Examples: parallel reviews, pipelines, complex tasks
```

---

## Further Reading

- [Claude Code Documentation](https://docs.anthropic.com/claude-code)
- [Swarm Orchestration Gist](https://gist.github.com/kieranklaassen/4f2aba89594a4aea4ad64d753984b2ea)
- [MCP Server Integration](https://modelcontextprotocol.io)

---

## License

MIT — Use freely, attribution appreciated.
