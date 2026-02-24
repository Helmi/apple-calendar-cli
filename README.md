<div align="center">

# Apple Calendar CLI

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)

🗓️ EventKit-native Apple Calendar CLI for macOS.  
CLI binary name: `applecal`.

</div>

## 🚀 Install

### 🍺 Homebrew (recommended)

```bash
brew tap Helmi/homebrew-tap
brew install applecal
```

### ⬇️ Direct binary download

Download the latest `applecal-<version>-macos-universal.zip` from Releases:

- https://github.com/Helmi/apple-calendar-cli/releases

Install manually:

```bash
curl -L -o applecal.zip \
  https://github.com/Helmi/apple-calendar-cli/releases/download/v0.1.0/applecal-0.1.0-macos-universal.zip
unzip applecal.zip
chmod +x applecal
mv applecal /opt/homebrew/bin/applecal
```

## ⚡ Quick start

```bash
# Health + permission state
applecal doctor --format json
applecal auth status --format json

# If needed, request full calendar access
applecal auth grant --format json

# List calendars
applecal calendars list --format json

# Create an event
applecal events create \
  --calendar "Work" \
  --title "Team Standup" \
  --start "2026-03-02T09:00:00+01:00" \
  --end "2026-03-02T09:30:00+01:00" \
  --format json
```

## 🧰 Commands

- `doctor`
- `auth status|grant|reset`
- `calendars list|get`
- `events list|get|search|create|update|delete`
- `completion bash|zsh|fish`
- `schema`

## 🔖 Versioning

Apple Calendar CLI follows SemVer (`MAJOR.MINOR.PATCH`).

- Product release example: `0.1.0`
- CLI binary: `applecal`
- JSON schema version is tracked separately for machine contract stability.

## 🛠️ Build from source

```bash
git clone https://github.com/Helmi/apple-calendar-cli.git
cd apple-calendar-cli
swift build -c release
swift test
```

## 📄 License

MIT — see `LICENSE`.
