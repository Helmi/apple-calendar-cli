# applecal (OpenClaw)

Use `applecal` for local Apple Calendar workflows.

## Install/build

```bash
cd ~/code/apple-calendar-cli
swift build
```

## Safe usage defaults

- Prefer JSON for automation: `--format json`
- Read before write when possible (`calendars list`, `events list`, `events get`)
- For recurring edits/deletes, include `--occurrence-start` and explicit `--scope`

## Common commands

```bash
swift run applecal calendars list --format json
swift run applecal events list --from 2026-03-01 --to 2026-03-08 --format json
swift run applecal events create --calendar cal-work --title "Standup" --start "2026-03-02T09:00:00+01:00" --end "2026-03-02T09:30:00+01:00" --format json
```
