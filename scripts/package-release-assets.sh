#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
COMPLETIONS_DIR="${DIST_DIR}/completions"
MAN_DIR="${DIST_DIR}/man"

mkdir -p "${COMPLETIONS_DIR}" "${MAN_DIR}"

swift run acal completion bash > "${COMPLETIONS_DIR}/acal.bash"
swift run acal completion zsh > "${COMPLETIONS_DIR}/_acal"
swift run acal completion fish > "${COMPLETIONS_DIR}/acal.fish"

cat > "${MAN_DIR}/acal.1" <<EOF
.TH ACAL 1
.SH NAME
acal \- A Calendar CLI
.SH SYNOPSIS
.B acal
<subcommand> [options]
.SH DESCRIPTION
EventKit-native A Calendar CLI for humans and agents.
.SH SUBCOMMANDS
doctor, auth, calendars, events, completion, schema
EOF

echo "Packaged completions to ${COMPLETIONS_DIR} and man page to ${MAN_DIR}"
