#!/usr/bin/env bash
set -euo pipefail

swift run acal doctor --format json
swift run acal auth status --format json
swift run acal calendars list --format table
swift run acal events create \
  --calendar cal-work \
  --title "Demo Event" \
  --start "2026-03-02T09:00:00+01:00" \
  --end "2026-03-02T09:30:00+01:00" \
  --repeat weekly \
  --byday mon,fri \
  --format json
