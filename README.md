<div align="center">

# acal

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)

An Apple Calendar CLI for macOS. Read and write your calendar from the terminal.

</div>

## What it is

`acal` is a single binary. Install it, grant access once, and any script or agent can read and write your Apple Calendar natively via EventKit — no server process required.

Works with shell scripts, cron jobs, and AI agents — anything that can run a command.

## Install

### Homebrew (recommended)

```bash
brew tap Helmi/homebrew-tap
brew install acal
```

### Direct download

Download the latest `acal-<version>-macos-universal.zip` from [Releases](https://github.com/Helmi/acal-apple-calendar-cli/releases):

```bash
curl -L -o acal.zip \
  https://github.com/Helmi/acal-apple-calendar-cli/releases/download/v0.2.1/acal-0.2.1-macos-universal.zip
unzip acal.zip
chmod +x acal
mv acal /opt/homebrew/bin/acal
```

## Quick start

```bash
# Check permissions and EventKit status
acal doctor

# Grant calendar access (first run)
acal auth grant

# List your calendars
acal calendars list

# List upcoming events as JSON
acal events list --format json

# Create an event
acal events create \
  --calendar "Work" \
  --title "Team Standup" \
  --start "2026-03-10T09:00:00+01:00" \
  --end "2026-03-10T09:30:00+01:00"
```

## Commands

| Command | What it does |
|---|---|
| `doctor` | Health check — EventKit access, permission state |
| `auth status\|grant\|reset` | Manage calendar permissions |
| `calendars list\|get` | List or inspect calendars |
| `events list\|get\|search\|create\|update\|delete` | Full event lifecycle, including recurrence-safe edits |
| `schema` | Print the stable JSON output contract |
| `completion bash\|zsh\|fish` | Install shell completions |

All commands accept `--format json` for machine-readable output.

### Event timestamp output timezone

Event commands (`events list|get|search|create|update`) render `start`/`end` in your **system timezone by default**.

Use one of these overrides when needed:

```bash
# Force UTC (Zulu)
acal events list --from 2026-03-10 --to 2026-03-11 --utc

# Force a specific IANA timezone
acal events list --from 2026-03-10 --to 2026-03-11 --output-timezone Europe/Berlin
```

`--utc` and `--output-timezone` are mutually exclusive.

## For agents and scripts

`acal` is designed to be called by AI agents with bash access. Every response uses the same envelope — `ok`, `data`, `error`, `meta` — so agents can handle success and failure without parsing workarounds.

```bash
acal events list --format json
```

```json
{
  "ok": true,
  "data": {
    "events": [
      {
        "id": "abc123",
        "calendarId": "work-cal-id",
        "title": "Team Standup",
        "start": "2026-03-10T09:00:00+01:00",
        "end": "2026-03-10T09:30:00+01:00",
        "timezone": "Europe/Berlin",
        "allDay": false,
        "recurrence": null,
        "alarms": []
      }
    ]
  },
  "meta": {
    "command": "events list",
    "schemaVersion": "1.0.0",
    "timestamp": "2026-03-10T08:00:00Z"
  }
}
```

Full contract: `acal schema`

## Build from source

```bash
git clone https://github.com/Helmi/acal-apple-calendar-cli.git
cd acal-apple-calendar-cli
swift build -c release
swift test
```

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

MIT — see [LICENSE](./LICENSE).
