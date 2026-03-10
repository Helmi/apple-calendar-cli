<div align="center">

# A Calendar CLI

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)

🗓️ EventKit-native A Calendar CLI for macOS.  
CLI binary name: `acal`.

</div>

## 🚀 Install

### 🍺 Homebrew (recommended)

```bash
brew tap Helmi/homebrew-tap
brew install acal
```

### ⬇️ Direct binary download

Download the latest `acal-<version>-macos-universal.zip` from Releases:

- https://github.com/Helmi/acal-cli/releases

Install manually:

```bash
curl -L -o acal.zip \
  https://github.com/Helmi/acal-cli/releases/download/v0.1.0/acal-0.1.0-macos-universal.zip
unzip acal.zip
chmod +x acal
mv acal /opt/homebrew/bin/acal
```

## ⚡ Quick start

```bash
# Health + permission state
acal doctor --format json
acal auth status --format json

# If needed, request full calendar access
acal auth grant --format json

# List calendars
acal calendars list --format json

# Create an event
acal events create \
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

A Calendar CLI follows SemVer (`MAJOR.MINOR.PATCH`).

- Product release example: `0.1.0`
- CLI binary: `acal`
- JSON schema version is tracked separately for machine contract stability.

## 🛠️ Build from source

```bash
git clone https://github.com/Helmi/acal-cli.git
cd acal-cli
swift build -c release
swift test
```

## 📄 License

MIT — see `LICENSE`.
