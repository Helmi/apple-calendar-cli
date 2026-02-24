<div align="center">

# applecal

**A fast, EventKit-native Apple Calendar CLI for macOS**

Machine-readable by default. Human-friendly when you need it.

</div>

---

## Why applecal?

`applecal` gives you reliable command-line access to Apple Calendar with a stable JSON contract, predictable exit codes, and recurrence-safe mutation semantics.

It is designed for two audiences:

- **Humans** who want quick calendar operations from terminal scripts
- **Agents/tools** that need deterministic output and robust error handling

---

## Current status

✅ Core CLI + EventKit runtime implemented locally  
✅ Build + tests green  
⏳ Release/distribution lane (GitHub release pipeline, notarization, Homebrew, publishing) still pending

---

## Features

- EventKit-backed runtime (default)
- Structured JSON envelope with schema versioning
- Deterministic machine error codes + exit code mapping
- Recurrence-aware create/update/delete semantics
- Alarms support
- Auth diagnostics (`doctor`, `auth status`, `auth grant`, `auth reset`)
- Calendar + event workflows (`list`, `get`, `search`, `create`, `update`, `delete`)
- Shell completions (`bash`, `zsh`, `fish`)

---

## Build

```bash
swift build
swift test
```

---

## Quick start

```bash
# 1) Sanity + auth
swift run applecal doctor --format json
swift run applecal auth status --format json

# 2) Inspect calendars
swift run applecal calendars list --format json

# 3) Create a recurring event
swift run applecal events create \
  --calendar cal-work \
  --title "Team Standup" \
  --start "2026-03-02T09:00:00+01:00" \
  --end "2026-03-02T09:30:00+01:00" \
  --repeat weekly \
  --byday mon,tue,wed,thu,fri \
  --alarm-minutes -10 \
  --format json
```

---

## Command surface

- `doctor`
- `auth status|grant|reset`
- `calendars list|get`
- `events list|get|search|create|update|delete`
- `completion bash|zsh|fish`
- `schema`

---

## JSON contract

All JSON responses use a stable envelope:

```json
{
  "ok": true,
  "data": {},
  "error": null,
  "meta": {
    "schemaVersion": "1.0.0",
    "timestamp": "2026-02-24T11:00:00Z",
    "command": "events list"
  }
}
```

---

## Local runtime modes

- **Default**: EventKit runtime (`EventKitCalendarStore`)
- **Deterministic test mode**: `APPLECAL_STORE=in_memory`

Auth behavior can be test-simulated via:

- `APPLECAL_AUTH_STATE`
- `APPLECAL_AUTH_GRANT_RESULT`

---

## Documentation

- Product requirements: `docs/PRD.md`
- ADRs: `docs/adr/`
- Privacy/telemetry policy: `docs/policy/privacy-telemetry.md`
- Release auth notes: `docs/RELEASE_AUTH.md`

---

## Roadmap (next lane)

- GitHub repo + branch protection setup
- Tagged release workflow (universal binaries)
- Notarization + code-signing integration
- Homebrew distribution
- Skills publishing + launch assets

No upload/publish has been performed yet.
