# applecal (Claude Code)

Use these patterns when automating Apple Calendar from Claude Code.

## Contract

- Always prefer `--format json`
- Parse `ok/data/error/meta` response envelope
- Respect deterministic exit codes

## Mutation workflow

1. List/get target first.
2. Apply create/update/delete with explicit fields.
3. Re-read target after mutation.

## Recurrence safety

- Use `--scope this|future|all`
- For `this`/`future`, pass `--occurrence-start`
