#!/usr/bin/env bash
set -euo pipefail

swift run applecal doctor --format json
swift run applecal auth status --format json
swift run applecal calendars list --format table
swift run applecal events create \
  --calendar cal-work \
  --title "Demo Event" \
  --start "2026-03-02T09:00:00+01:00" \
  --end "2026-03-02T09:30:00+01:00" \
  --repeat weekly \
  --byday mon,fri \
  --format json
