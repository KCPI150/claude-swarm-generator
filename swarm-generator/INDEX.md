# Swarm Generator Index (v2)

Quick reference for available components.

## v2 Changes
- **Sequential execution**: Agents run one at a time, leader manages task state
- **No TaskList in prompts**: Subagents don't have task tools, prompts updated
- **Better detection**: Checks actual files, not just patterns

## Tech Stacks

| Stack | Formatter | Linter | Test Runner |
|-------|-----------|--------|-------------|
| python | ruff | ruff check | pytest |
| angular | prettier | eslint | ng test |
| kotlin | ktlint | detekt | gradle test |
| sql | sqlfluff | sqlfluff lint | - |
| terraform | terraform fmt | tflint | terraform validate |
| airflow | ruff | ruff check | airflow dags test |
| yaml | prettier | yamllint | yq |

## Templates

| Template | Agents | Flow | Execution |
|----------|--------|------|-----------|
| dev-pipeline | builder, linter, validator, documenter | Build → Lint → Test → Document | Sequential |
| code-review | reviewer, security, approver | Review → Security → Approve | Sequential |
| refactor | analyzer, planner, builder, validator | Analyze → Plan → Implement → Validate | Sequential |

## Hooks

### Formatters (PostToolUse)
- `ruff-format.sh` - Python/Airflow
- `prettier.sh` - Angular/YAML
- `ktlint.sh` - Kotlin
- `sqlfluff-format.sh` - SQL
- `terraform-fmt.sh` - Terraform

### Validators (PostToolUse)
- `ruff-check.sh` - Python
- `eslint.sh` - Angular
- `tflint.sh` - Terraform
- `yamllint.sh` - YAML

### Security (PreToolUse)
- `secrets-check.sh` - Blocks secrets in code
- `block-dangerous.sh` - Blocks dangerous commands

### Common
- `notify-macos.sh` - Desktop notifications

## Usage

```bash
/deploy-swarm                              # Interactive
/deploy-swarm python                       # Explicit stack
/deploy-swarm angular dev-pipeline "Add feature"

/cleanup-swarm
```

## Execution Model

```
Leader (main session)
  │
  ├─ Create tasks with dependencies
  │
  ├─ For each task in order:
  │   ├─ Mark task in_progress
  │   ├─ Spawn agent (wait for completion)
  │   ├─ Read agent result
  │   └─ Mark task completed
  │
  └─ Report final results
```

## Archived

Previous stacks (rust, go, typescript) in:
`~/.claude/swarm-generator/.archive/`
