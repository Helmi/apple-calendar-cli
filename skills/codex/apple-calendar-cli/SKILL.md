# applecal (Codex)

Codex-oriented command patterns for local calendar automation.

## Recommended defaults

```bash
swift run applecal auth status --format json
swift run applecal calendars list --format json
```

## Read/query

```bash
swift run applecal events list --from 2026-03-01 --to 2026-03-08 --format json
swift run applecal events search --query standup --from 2026-03-01 --to 2026-03-31 --format json
```

## Mutations

```bash
swift run applecal events create --calendar cal-work --title "Review" --start "2026-03-05T15:00:00+01:00" --end "2026-03-05T15:30:00+01:00" --format json
```
