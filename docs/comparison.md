# Comparison: applecal vs iCalBuddy vs plan.swift vs Calendar MCP

| Tool | Core focus | Write support | Recurrence edit scope | Agent-ready JSON | Requires always-on server |
|---|---|---:|---:|---:|---:|
| applecal | Native macOS CLI, full lifecycle | ✅ | ✅ (`this`/`future`/`all`) | ✅ stable envelope | ❌ |
| iCalBuddy | Legacy read/list tooling | Limited | ❌ | ❌ | ❌ |
| plan.swift | Great interactive read UX | ❌ | ❌ | partial | ❌ |
| MCP calendar servers | Tool-call bridge for agents | ✅ | varies | varies | ✅ |

## Why applecal exists

1. Full CRUD and recurrence semantics in one local CLI.
2. Stable error/exit-code contract for automation.
3. Human CLI UX and shell-native workflow without mandatory MCP layer.
