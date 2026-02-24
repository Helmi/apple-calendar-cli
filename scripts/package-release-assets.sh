#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
COMPLETIONS_DIR="${DIST_DIR}/completions"
MAN_DIR="${DIST_DIR}/man"

mkdir -p "${COMPLETIONS_DIR}" "${MAN_DIR}"

swift run applecal completion bash > "${COMPLETIONS_DIR}/applecal.bash"
swift run applecal completion zsh > "${COMPLETIONS_DIR}/_applecal"
swift run applecal completion fish > "${COMPLETIONS_DIR}/applecal.fish"

cat > "${MAN_DIR}/applecal.1" <<EOF
.TH APPLECAL 1
.SH NAME
applecal \- Apple Calendar CLI
.SH SYNOPSIS
.B applecal
<subcommand> [options]
.SH DESCRIPTION
EventKit-native Apple Calendar CLI for humans and agents.
.SH SUBCOMMANDS
doctor, auth, calendars, events, completion, schema
EOF

echo "Packaged completions to ${COMPLETIONS_DIR} and man page to ${MAN_DIR}"
