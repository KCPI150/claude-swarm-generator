# Claude Swarm Generator

Multi-agent swarm orchestration for Claude Code with automated hooks.

## Features

- **Stacks**: python, angular, kotlin, sql, terraform, airflow, yaml
- **Templates**: dev-pipeline, code-review, refactor
- **Hooks**: Auto-formatting, linting, secrets detection
- **Skills**: `/deploy-swarm`, `/cleanup-swarm`

## Installation

```bash
git clone https://github.com/KCPI150/claude-swarm-generator
cd claude-swarm-generator
chmod +x install.sh
./install.sh
```

**Restart Claude Code** for hooks to take effect.

## Usage

```bash
/deploy-swarm                    # Interactive - detects stack
/deploy-swarm python             # Specify stack
/deploy-swarm yaml refactor      # Specify stack and template
/cleanup-swarm                   # Clean up tasks after swarm
```

## Templates

| Template | Workflow |
|----------|----------|
| dev-pipeline | Build → Lint → Test → Document |
| code-review | Review → Security → Approve → Document |
| refactor | Analyze → Plan → Implement → Validate → Document |

## Hooks

Hooks run automatically on file edits:

| Hook | Trigger | Action |
|------|---------|--------|
| ruff-format.sh | PostToolUse (Write/Edit) | Format Python |
| prettier.sh | PostToolUse (Write/Edit) | Format JS/TS/YAML |
| ruff-check.sh | PostToolUse (Write/Edit) | Lint Python |
| secrets-check.sh | PreToolUse (Write/Edit) | Block credentials |
| block-dangerous.sh | PreToolUse (Bash) | Block dangerous commands |

## Output

Each swarm creates documentation in your project:

```
your-project/
└── docs/
    └── SWARM-SUMMARY.md    # Agent summaries and final status
```

## Uninstall

```bash
./uninstall.sh
```

## Requirements

- Claude Code CLI
- `jq` (for automatic hook configuration)
- Stack-specific tools (ruff, prettier, etc.) for hooks to work

## License

MIT
