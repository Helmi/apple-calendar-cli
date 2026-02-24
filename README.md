# applecal

EventKit-native Apple Calendar CLI for macOS, optimized for both humans and agents.

## Status

Local development build. Core command surface and JSON contract are implemented in-repo.

## Build

```bash
swift build
```

## Quickstart

```bash
# Diagnostics + auth
swift run applecal doctor --format json
swift run applecal auth status --format json

# Calendars
swift run applecal calendars list --format json
swift run applecal calendars get --id cal-default --format json

# Create a recurring event
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

## Command groups

- `doctor`
- `auth status|grant|reset`
- `calendars list|get`
- `events list|get|search|create|update|delete`
- `completion bash|zsh|fish`
- `schema`

## Output contract

JSON mode returns a stable envelope:

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

## Notes

- Current implementation uses an in-memory store for deterministic local development and testability.
- EventKit auth diagnostics/grant flow are wired and can be environment-simulated for test scenarios.
- Release publishing, notarization, and Homebrew distribution are intentionally deferred to release tasks.
