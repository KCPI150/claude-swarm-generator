---
name: cleanup-swarm
description: "Clean up stale tasks after a swarm run. Does NOT delete documentation or global hooks."
---

# Cleanup Swarm

Clean up after a swarm run completes.

## Usage

```
/cleanup-swarm
```

## What This Does

**Cleans up:**
- Stale/completed tasks from the task list

**Does NOT delete:**
- `docs/SWARM-SUMMARY.md` (project documentation - keep it!)
- Global hooks in `~/.claude/settings.json` (intentionally persistent)

## Instructions

### Step 1: Check Task Status

```javascript
TaskList()
```

Report current state:
```
Current tasks:
- #14 [completed] Analyze
- #15 [completed] Plan
- #16 [completed] Build
- #17 [completed] Validate
- #18 [completed] Document

All tasks completed.
```

### Step 2: Confirm Cleanup

Ask user:
```
Delete completed swarm tasks from task list? [y/N]

Note: This will NOT delete:
- docs/SWARM-SUMMARY.md (your project documentation)
- Global hooks (they remain active)
```

### Step 3: Delete Completed Tasks

If confirmed:
```javascript
TaskUpdate({ taskId: "14", status: "deleted" })
TaskUpdate({ taskId: "15", status: "deleted" })
// etc.
```

### Step 4: Report

```
Cleanup Complete

Tasks removed: 5
Documentation preserved: docs/SWARM-SUMMARY.md
Global hooks: unchanged
```

## What About Hooks?

Global hooks in `~/.claude/settings.json` are **intentionally persistent** - they apply to all sessions and subagents. Don't remove them unless you specifically want to disable auto-formatting.

To manually disable hooks, edit `~/.claude/settings.json` directly.

## What About Documentation?

The summary file at `docs/SWARM-SUMMARY.md` is **project documentation** showing what the swarm accomplished. Keep it for reference and commit it with your code.
